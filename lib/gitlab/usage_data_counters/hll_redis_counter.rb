# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    module HLLRedisCounter
      DEFAULT_WEEKLY_KEY_EXPIRY_LENGTH = 6.weeks
      DEFAULT_DAILY_KEY_EXPIRY_LENGTH = 29.days
      DEFAULT_REDIS_SLOT = ''.freeze

      UnknownEvent = Class.new(StandardError)
      UnknownAggregation = Class.new(StandardError)

      KNOWN_EVENTS_PATH = 'lib/gitlab/usage_data_counters/known_events.yml'.freeze
      ALLOWED_AGGREGATIONS = %i(daily weekly).freeze

      # Track event on entity_id
      # Increment a Redis HLL counter for unique event_name and entity_id
      #
      # All events should be added to know_events file lib/gitlab/usage_data_counters/known_events.yml
      #
      # Event example:
      #
      # - name: g_compliance_dashboard # Unique event name
      #   redis_slot: compliance       # Optional slot name, if not defined it will use name as a slot, used for totals
      #   category: compliance         # Group events in categories
      #   expiry: 29                   # Optional expiration time in days, default value 29 days for daily and 6.weeks for weekly
      #   aggregation: daily           # Aggregation level, keys are stored daily or weekly
      # Usage:
      #
      # * Track event: Gitlab::UsageDataCounters::HLLRedisCounter.track_event(user_id, 'g_compliance_dashboard')
      # * Get unique counts per user: Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(event_names: 'g_compliance_dashboard', start_date: 28.days.ago, end_date: Date.current)
      class << self
        include Gitlab::Utils::UsageData

        def track_event(entity_id, event_name, context: '', time: Time.zone.now)
          return unless Gitlab::CurrentSettings.usage_ping_enabled?

          event = event_for(event_name)

          raise UnknownEvent.new("Unknown event #{event_name}") unless event.present?

          # Increment unique event for given context
          # Track events in context level
          if context.present?
            Gitlab::Redis::HLL.add(key: redis_key(event, time, context), value: entity_id, expiry: expiry(event))
          end

          # Increment unique event globaly
          Gitlab::Redis::HLL.add(key: redis_key(event, time), value: entity_id, expiry: expiry(event))
        end

        # Get the unique events in same category and slot
        # When context is given it will get the union of events in the given context
        def unique_events(event_names:, start_date:, end_date:, context: '')
          events = events_for(Array(event_names).map(&:to_s))

          raise 'Events should be in same slot' unless events_in_same_slot?(events)
          raise 'Events should be in same category' unless events_in_same_category?(events)
          raise 'Events should have same aggregation level' unless events_same_aggregation?(events)

          aggregation = events.first[:aggregation]

          keys = keys_for_aggregation(aggregation, events: events, start_date: start_date, end_date: end_date, context: context)

          redis_usage_data { Gitlab::Redis::HLL.count(keys: keys) }
        end

        def categories
          @categories ||= known_events.map { |event| event[:category] }.uniq
        end

        # @param category [String] the category name
        # @return [Array<String>] list of event names for given category
        def events_for_category(category)
          known_events.select { |event| event[:category] == category.to_s }.map { |event| event[:name] }
        end

        # Get the unique events data for all known_events
        def unique_events_data
          categories.each_with_object({}) do |category, category_results|
            events_names = events_for_category(category)

            event_results = events_names.each_with_object({}) do |event, hash|
              hash["#{event}_weekly"] = unique_events(event_names: event, start_date: 7.days.ago.to_date, end_date: Date.current)
              hash["#{event}_monthly"] = unique_events(event_names: event, start_date: 4.weeks.ago.to_date, end_date: Date.current)
            end

            if eligible_for_totals?(events_names)
              event_results["#{category}_total_unique_counts_weekly"] = unique_events(event_names: events_names, start_date: 7.days.ago.to_date, end_date: Date.current)
              event_results["#{category}_total_unique_counts_monthly"] = unique_events(event_names: events_names, start_date: 4.weeks.ago.to_date, end_date: Date.current)
            end

            category_results["#{category}"] = event_results
          end
        end

        def known_event?(event_name)
          event_for(event_name).present?
        end

        private

        # Allow to add totals for events that are in the same redis slot, category and have the same aggregation level
        # and if there are more than 1 event
        def eligible_for_totals?(events_names)
          return false if events_names.size <= 1

          events = events_for(events_names)
          events_in_same_slot?(events) && events_in_same_category?(events) && events_same_aggregation?(events)
        end

        def keys_for_aggregation(aggregation, events:, start_date:, end_date:, context: '')
          if aggregation.to_sym == :daily
            daily_redis_keys(events: events, start_date: start_date, end_date: end_date, context: context)
          else
            weekly_redis_keys(events: events, start_date: start_date, end_date: end_date, context: context)
          end
        end

        def known_events
          @known_events ||= YAML.load_file(Rails.root.join(KNOWN_EVENTS_PATH)).map(&:with_indifferent_access)
        end

        def known_events_names
          known_events.map { |event| event[:name] }
        end

        def events_in_same_slot?(events)
          # if we check one event then redis_slot is only one to check
          return true if events.size == 1

          slot = events.first[:redis_slot]
          events.all? { |event| event[:redis_slot].present? && event[:redis_slot] == slot }
        end

        def events_in_same_category?(events)
          category = events.first[:category]
          events.all? { |event| event[:category] == category }
        end

        def events_same_aggregation?(events)
          aggregation = events.first[:aggregation]
          events.all? { |event| event[:aggregation] == aggregation }
        end

        def expiry(event)
          return event[:expiry].days if event[:expiry].present?

          event[:aggregation].to_sym == :daily ? DEFAULT_DAILY_KEY_EXPIRY_LENGTH : DEFAULT_WEEKLY_KEY_EXPIRY_LENGTH
        end

        def event_for(event_name)
          known_events.find { |event| event[:name] == event_name.to_s }
        end

        def events_for(event_names)
          known_events.select { |event| event_names.include?(event[:name]) }
        end

        def redis_slot(event)
          event[:redis_slot] || DEFAULT_REDIS_SLOT
        end

        # Compose the key in order to store events daily or weekly
        def redis_key(event, time, context = '')
          raise UnknownEvent.new("Unknown event #{event[:name]}") unless known_events_names.include?(event[:name].to_s)
          raise UnknownAggregation.new("Use :daily or :weekly aggregation") unless ALLOWED_AGGREGATIONS.include?(event[:aggregation].to_sym)

          key = apply_slot(event)
          key = apply_time_aggregation(key, time, event)
          key = "#{context}_#{key}" if context.present?
          key
        end

        def apply_slot(event)
          slot = redis_slot(event)
          if slot.present?
            event[:name].to_s.gsub(slot, "{#{slot}}")
          else
            "{#{event[:name]}}"
          end
        end

        def apply_time_aggregation(key, time, event)
          if event[:aggregation].to_sym == :daily
            year_day = time.strftime('%G-%j')
            "#{year_day}-#{key}"
          else
            year_week = time.strftime('%G-%V')
            "#{key}-#{year_week}"
          end
        end

        def daily_redis_keys(events:, start_date:, end_date:, context: '')
          (start_date.to_date..end_date.to_date).map do |date|
            events.map { |event| redis_key(event, date, context) }
          end.flatten
        end

        def weekly_redis_keys(events:, start_date:, end_date:, context: '')
          weeks = end_date.to_date.cweek - start_date.to_date.cweek
          weeks = 1 if weeks == 0

          (0..(weeks - 1)).map do |week_increment|
            events.map { |event| redis_key(event, start_date + week_increment * 7.days, context) }
          end.flatten
        end
      end
    end
  end
end
