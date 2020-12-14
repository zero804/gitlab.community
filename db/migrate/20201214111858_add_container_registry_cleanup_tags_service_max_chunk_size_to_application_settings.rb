# frozen_string_literal: true
class AddContainerRegistryCleanupTagsServiceMaxChunkSizeToApplicationSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    unless column_exists?(:application_settings, :container_registry_cleanup_tags_service_max_chunk_size)
      add_column(:application_settings, :container_registry_cleanup_tags_service_max_chunk_size, :integer, default: 200, null: false)
    end
  end

  def down
    if column_exists?(:application_settings, :container_registry_cleanup_tags_service_max_chunk_size)
      remove_column(:application_settings, :container_registry_cleanup_tags_service_max_chunk_size)
    end
  end
end
