# frozen_string_literal: true

module Elastic
  class MigrationWorker
    include ApplicationWorker
    include Gitlab::ExclusiveLeaseHelpers
    # There is no onward scheduling and this cron handles work from across the
    # application, so there's no useful context to add.
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    feature_category :global_search
    idempotent!
    urgency :throttled

    def perform
      return false unless Gitlab::CurrentSettings.elasticsearch_indexing?
      return false unless helper.alias_exists?

      in_lock(self.class.name.underscore, ttl: 1.day, retries: 10, sleep_sec: 1) do
        migration = current_migration

        unless migration
          logger.info 'MigrationWorker: no migration available'
          break false
        end

        unless helper.index_exists?(index_name: helper.migrations_index_name)
          logger.info 'MigrationWorker: creating migrations index'
          helper.create_migrations_index
        end

        if migration.halted?
          logger.info "MigrationWorker: migration[#{migration.name}] has been halted. All future migrations will be halted because of that. Exiting"
          unpause_indexing!(migration)

          break false
        end

        execute_migration(migration)

        completed = migration.completed?
        logger.info "MigrationWorker: migration[#{migration.name}] updating with completed: #{completed}"
        migration.save!(completed: completed)

        unpause_indexing!(migration) if completed

        Elastic::DataMigrationService.drop_migration_has_finished_cache!(migration)
      end
    end

    private

    def execute_migration(migration)
      if migration.persisted? && !migration.batched?
        logger.info "MigrationWorker: migration[#{migration.name}] did not execute migrate method since it was already executed. Waiting for migration to complete"
      else
        pause_indexing!(migration)

        logger.info "MigrationWorker: migration[#{migration.name}] executing migrate method"
        migration.migrate

        if migration.batched? && !migration.completed?
          logger.info "MigrationWorker: migration[#{migration.name}] kicking off next migration batch"
          Elastic::MigrationWorker.perform_in(migration.throttle_delay)
        end
      end
    end

    def current_migration
      completed_migrations = Elastic::MigrationRecord.persisted_versions(completed: true)

      Elastic::DataMigrationService.migrations.find { |migration| !completed_migrations.include?(migration.version) }
    end

    def pause_indexing!(migration)
      return unless migration.pause_indexing?
      return if migration.load_state[:pause_indexing].present?

      pause_indexing = !Gitlab::CurrentSettings.elasticsearch_pause_indexing?
      migration.save_state!(pause_indexing: pause_indexing)

      if pause_indexing
        logger.info 'MigrationWorker: Pausing indexing'
        Gitlab::CurrentSettings.update!(elasticsearch_pause_indexing: true)
      end
    end

    def unpause_indexing!(migration)
      return unless migration.pause_indexing?
      return unless migration.load_state[:pause_indexing]

      logger.info 'MigrationWorker: unpausing indexing'
      Gitlab::CurrentSettings.update!(elasticsearch_pause_indexing: false)
    end

    def helper
      Gitlab::Elastic::Helper.default
    end

    def logger
      @logger ||= ::Gitlab::Elasticsearch::Logger.build
    end
  end
end
