# frozen_string_literal: true

module Gitlab
  class UsageData
    class Metric
      class Definition
        extend ::Gitlab::UsageData::Metric::Schema

        attr_reader :path
        attr_reader :attributes

        def initialize(path, opts = {})
          @path = path
          @attributes = opts
        end

        # The key is defined by default_generation and full_path
        def key
          full_path[default_generation.to_sym]
        end

        def to_h
          attributes
        end

        def validate!
          self.class.schemer.validate(attributes.stringify_keys).map do |error|
            Gitlab::ErrorTracking.track_and_raise_for_dev_exception(Metric::InvalidMetricError.new("Invalid #{error["data_pointer"]} for `#{path}`"))
          end
        end

        alias_method :to_dictionary, :to_h

        class << self
          def paths
            @paths ||= [Rails.root.join('lib', 'gitlab', 'usage_data', 'metrics_definitions', '**', '*.yml')]
          end

          def definitions
            @definitions ||= load_all!
          end

          private

          def load_all!
            paths.each_with_object({}) do |glob_path, definitions|
              load_all_from_path!(definitions, glob_path)
            end
          end

          def load_from_file(path)
            definition = File.read(path)
            definition = YAML.safe_load(definition)
            definition.deep_symbolize_keys!

            self.new(path, definition).tap(&:validate!)
          rescue => e
            Gitlab::ErrorTracking.track_and_raise_for_dev_exception(Metric::InvalidMetricError.new("Invalid definition for `#{path}`: #{e}"))
          end

          def load_all_from_path!(definitions, glob_path)
            Dir.glob(glob_path).each do |path|
              definition = load_from_file(path)

              if previous = definitions[definition.key]
                Gitlab::ErrorTracking.track_and_raise_for_dev_exception(Metric::InvalidMetricError.new("Metric '#{definition.key}' is already defined in '#{previous.path}'"))
              end

              definitions[definition.key] = definition
            end
          end
        end

        private

        def method_missing(method, *args)
          attributes[method] || super
        end
      end
    end
  end
end
