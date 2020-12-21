# frozen_string_literal: true

module Gitlab
  module Elastic
    class Helper
      ES_MAPPINGS_CLASSES = [
          Project,
          MergeRequest,
          Snippet,
          Note,
          Milestone,
          ProjectWiki,
          Repository
      ].freeze

      ES_SEPARATE_CLASSES = [
        Issue
      ].freeze

      attr_reader :version, :client
      attr_accessor :target_name

      def initialize(
        version: ::Elastic::MultiVersionUtil::TARGET_VERSION,
        client: nil,
        target_name: nil)

        proxy = self.class.create_proxy(version)

        @client = client || proxy.client
        @target_name = target_name || proxy.index_name
        @version = version
      end

      class << self
        def create_proxy(version = nil)
          Project.__elasticsearch__.version(version)
        end

        def default
          @default ||= self.new
        end
      end

      def default_settings
        ES_MAPPINGS_CLASSES.inject({}) do |settings, klass|
          settings.deep_merge(klass.__elasticsearch__.settings.to_hash)
        end
      end

      def default_mappings
        mappings = ES_MAPPINGS_CLASSES.inject({}) do |m, klass|
          m.deep_merge(klass.__elasticsearch__.mappings.to_hash)
        end
        mappings.deep_merge(::Elastic::Latest::CustomLanguageAnalyzers.custom_analyzers_mappings)
      end

      def migrations_index_name
        "#{target_name}-migrations"
      end

      def create_migrations_index
        settings = { number_of_shards: 1 }
        mappings = {
          _doc: {
            properties: {
              completed: {
                type: 'boolean'
              },
              state: {
                type: 'object'
              },
              started_at: {
                type: 'date'
              },
              completed_at: {
                type: 'date'
              }
            }
          }
        }

        create_index_options = {
          index: migrations_index_name,
          body: {
            settings: settings.to_hash,
            mappings: mappings.to_hash
          }
        }.merge(additional_index_options)

        client.indices.create create_index_options

        migrations_index_name
      end

      def standalone_indices_proxies
        ES_SEPARATE_CLASSES.map do |class_name|
          ::Elastic::Latest::ApplicationClassProxy.new(class_name, use_separate_indices: true)
        end
      end

      def create_standalone_indices(options: {})
        standalone_indices_proxies.map do |proxy|
          alias_name = proxy.index_name
          new_index_name = "#{alias_name}-#{Time.now.strftime("%Y%m%d-%H%M")}"

          if alias_exists?(name: alias_name)
            raise "Index under '#{alias_name}' already exists"
          end

          settings = proxy.settings
          settings = settings.merge(options[:settings]) if options[:settings]

          mappings = proxy.mappings
          mappings = mappings.merge(options[:mappings]) if options[:mappings]

          create_index_options = {
            index: new_index_name,
            body: {
              settings: settings.to_hash,
              mappings: mappings.to_hash
            }
          }.merge(additional_index_options)

          client.indices.create create_index_options

          client.indices.put_alias(name: alias_name, index: new_index_name)

          new_index_name
        end
      end

      def create_empty_index(with_alias: true, options: {})
        new_index_name = options[:index_name] || "#{target_name}-#{Time.now.strftime("%Y%m%d-%H%M")}"

        if with_alias ? index_exists? : index_exists?(index_name: new_index_name)
          raise "Index under '#{with_alias ? target_name : new_index_name}' already exists, use `recreate_index` to recreate it."
        end

        settings = default_settings
        settings.merge!(options[:settings]) if options[:settings]

        mappings = default_mappings
        mappings.merge!(options[:mappings]) if options[:mappings]

        create_index_options = {
          index: new_index_name,
          body: {
            settings: settings.to_hash,
            mappings: mappings.to_hash
          }
        }.merge(additional_index_options)

        client.indices.create create_index_options
        client.indices.put_alias(name: target_name, index: new_index_name) if with_alias

        new_index_name
      end

      def delete_index(index_name: nil)
        result = client.indices.delete(index: target_index_name(target: index_name))
        result['acknowledged']
      rescue ::Elasticsearch::Transport::Transport::Errors::NotFound => e
        Gitlab::ErrorTracking.log_exception(e)
        false
      end

      def index_exists?(index_name: nil)
        client.indices.exists?(index: index_name || target_name) # rubocop:disable CodeReuse/ActiveRecord
      end

      def alias_exists?(name: nil)
        client.indices.exists_alias(name: name || target_name)
      end

      # Calls Elasticsearch refresh API to ensure data is searchable
      # immediately.
      # https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-refresh.html
      # By default refreshes main and standalone_indices
      def refresh_index(index_name: nil)
        indices = if index_name.nil?
                    [target_name] + standalone_indices_proxies.map(&:index_name)
                  else
                    [index_name]
                  end

        indices.each do |index|
          client.indices.refresh(index: index)
        end
      end

      def index_size(index_name: nil)
        client.indices.stats['indices'][index_name || target_index_name]['total']
      end

      def documents_count(index_name: nil)
        index = target_index_name(target: index_name || target_index_name)

        client.indices.stats.dig('indices', index, 'primaries', 'docs', 'count')
      end

      def index_size_bytes
        index_size['store']['size_in_bytes']
      end

      def cluster_free_size_bytes
        client.cluster.stats['nodes']['fs']['free_in_bytes']
      end

      def reindex(from: target_index_name, to:, wait_for_completion: false)
        body = {
          source: {
            index: from
          },
          dest: {
            index: to
          }
        }

        response = client.reindex(body: body, slices: 'auto', wait_for_completion: wait_for_completion)

        response['task']
      end

      def task_status(task_id:)
        client.tasks.get(task_id: task_id)
      end

      def get_settings(index_name: nil)
        index = index_name || target_index_name
        settings = client.indices.get_settings(index: index)
        settings.dig(index, 'settings', 'index')
      end

      def update_settings(index_name: nil, settings:)
        client.indices.put_settings(index: index_name || target_index_name, body: settings)
      end

      def switch_alias(from: target_index_name, to:)
        actions = [
          {
            remove: { index: from, alias: target_name }
          },
          {
            add: { index: to, alias: target_name }
          }
        ]

        body = { actions: actions }
        client.indices.update_aliases(body: body)
      end

      # This method is used when we need to get an actual index name (if it's used through an alias)
      def target_index_name(target: nil)
        target ||= target_name

        if alias_exists?(name: target)
          client.indices.get_alias(name: target).each_key.first
        else
          target
        end
      end

      private

      def additional_index_options
        {}.tap do |options|
          # include_type_name defaults to false in ES7. This will ensure ES7
          # behaves like ES6 when creating mappings. See
          # https://www.elastic.co/blog/moving-from-types-to-typeless-apis-in-elasticsearch-7-0
          # for more information. We also can't set this for any versions before
          # 6.8 as this parameter was not supported. Since it defaults to true in
          # all 6.x it's safe to only set it for 7.x.
          options[:include_type_name] = true if Gitlab::VersionInfo.parse(client.info['version']['number']).major == 7
        end
      end
    end
  end
end
