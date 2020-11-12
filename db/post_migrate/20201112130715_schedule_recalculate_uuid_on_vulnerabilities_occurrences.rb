# frozen_string_literal: true

class ScheduleRecalculateUuidOnVulnerabilitiesOccurrences < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  MIGRATION = 'RecalculateVulnerabilitiesOccurrencesUuid'
  BATCH_SIZE = 2_500

  disable_ddl_transaction!

  class VulnerabilitiesFinding < ActiveRecord::Base
    include ::EachBatch

    self.table_name = "vulnerability_occurrences"
  end

  def up
    say "Scheduling #{MIGRATION} jobs"

    bulk_queue_background_migration_jobs_by_range(
      VulnerabilitiesFinding,
      MIGRATION,
      batch_size: BATCH_SIZE
    )
  end

  def down
    # no-op
  end
end
