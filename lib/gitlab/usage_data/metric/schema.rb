# frozen_string_literal: true

module Gitlab
  class UsageData
    class Metric
      module Schema
        METRIC_SCHEMA_PATH = Rails.root.join('lib', 'gitlab', 'usage_data', 'metrics_definitions', 'metric_schema.json')

        def schemer
          @schemer ||= ::JSONSchemer.schema(Pathname.new(METRIC_SCHEMA_PATH))
        end
      end
    end
  end
end
