class EnsureRemoteMirrorColumns < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  # rubocop:disable Migration/Datetime
  # rubocop:disable Migration/PreventStrings
  def up
    add_column :remote_mirrors, :last_update_started_at, :datetime unless column_exists?(:remote_mirrors, :last_update_started_at)
    add_column :remote_mirrors, :remote_name, :string unless column_exists?(:remote_mirrors, :remote_name)

    unless column_exists?(:remote_mirrors, :only_protected_branches)
      add_column_with_default(:remote_mirrors, # rubocop:disable Migration/AddColumnWithDefault
                              :only_protected_branches,
                              :boolean,
                              default: false,
                              allow_null: false)
    end
  end
  # rubocop:enable Migration/PreventStrings
  # rubocop:enable Migration/Datetime

  def down
    # db/migrate/20180503131624_create_remote_mirrors.rb will remove the table
  end
end
