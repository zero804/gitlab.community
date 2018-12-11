# frozen_string_literal: true

module Gitlab
  module Geo
    class Cache
      attr_reader :namespace, :backend

      def initialize(backend: Rails.cache)
        @backend = backend
        @namespace = :geo
      end

      def active?
        if backend.respond_to?(:active?)
          backend.active?
        else
          true
        end
      end

      def cache_key(key)
        "#{namespace}:#{key}:#{Rails.version}"
      end

      def expire(key)
        backend.delete(cache_key(key))
      end

      def read(key, klass = nil)
        value = backend.read(cache_key(key))
        value = parse_value(value, klass) if value
        value
      end

      def write(key, value, options = {})
        backend.write(cache_key(key), *[value.to_json, options].reject(&:blank?))
      end

      def fetch(key, options = {}, &block)
        klass = options.delete(:klass)
        value = read(key, klass)
        return value unless value.nil?

        value = yield

        write(key, value, options)

        value
      end

      private

      def parse_value(raw, klass)
        value = ActiveSupport::JSON.decode(raw)

        case value
        when Hash then parse_entry(value, klass)
        when Array then parse_entries(value, klass)
        else
          value
        end
      rescue ActiveSupport::JSON.parse_error
        nil
      end

      def parse_entry(raw, klass)
        klass.new(raw) if valid_entry?(raw, klass)
      end

      def valid_entry?(raw, klass)
        return false unless klass && raw.is_a?(Hash)

        (raw.keys - klass.attribute_names).empty?
      end

      def parse_entries(values, klass)
        values.map { |value| parse_entry(value, klass) }.compact
      end
    end
  end
end
