# frozen_string_literal: true

class AddSquashCommitShaIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = "index_merge_requests_on_squash_commit_sha"

  disable_ddl_transaction!

  def up
    add_concurrent_index :merge_requests,
      :squash_commit_sha,
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index :merge_requests,
      :squash_commit_sha,
      name: INDEX_NAME
  end
end
