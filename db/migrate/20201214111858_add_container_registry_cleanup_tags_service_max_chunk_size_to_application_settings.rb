# frozen_string_literal: true

class AddContainerRegistryCleanupTagsServiceMaxChunkSizeToApplicationSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column(:application_settings, :container_registry_cleanup_tags_service_max_chunk_size, :integer, default: 200, null: false)
  end
end
