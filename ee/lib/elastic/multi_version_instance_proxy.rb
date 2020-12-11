# frozen_string_literal: true

# Agnostic proxy to decide which version of elastic_target to use based on method being reads or writes
module Elastic
  class MultiVersionInstanceProxy
    include MultiVersionUtil

    def initialize(data_target, use_separate_indices: false)
      @data_target = data_target
      @data_class = get_data_class(data_target.class)
      @use_separate_indices = use_separate_indices

      generate_forwarding
    end

    private

    def proxy_class_name
      "#{@data_class.name}InstanceProxy"
    end
  end
end
