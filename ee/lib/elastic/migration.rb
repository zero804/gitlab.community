# frozen_string_literal: true

module Elastic
  class Migration
    include Elastic::MigrationOptions
    include Elastic::MigrationState

    attr_reader :version

    def initialize(version)
      @version = version
    end

    def migrate
      raise NotImplementedError, 'Please extend Elastic::Migration'
    end

    def completed?
      raise NotImplementedError, 'Please extend Elastic::Migration'
    end

    private

    def helper
      @helper ||= Gitlab::Elastic::Helper.default
    end

    def client
      helper.client
    end

    def migration_record
      Elastic::DataMigrationService[version]
    end

    def fail_migration_halt_error!(retry_attempt: 0)
      set_migration_state(
        retry_attempt: retry_attempt,
        halted: true
      )
    end

    def log(message)
      logger.info "[Elastic::Migration: #{self.version}] #{message}"
    end

    def log_raise(message)
      logger.error "[Elastic::Migration: #{self.version}] #{message}"
      raise message
    end

    def logger
      @logger ||= ::Gitlab::Elasticsearch::Logger.build
    end
  end
end
