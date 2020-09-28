# frozen_string_literal: true

class FixServicesVarcharLimits < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      change_column :services, :type, :text # rubocop:disable Migration/WithLockRetriesDisallowedMethod
    end
  end

  def down
    # no op
  end
end
