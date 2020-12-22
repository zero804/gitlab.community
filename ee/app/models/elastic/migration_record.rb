# frozen_string_literal: true

module Elastic
  class MigrationRecord
    attr_reader :version, :name, :filename

    delegate :migrate, :skip_migration?, :completed?, :batched?, :throttle_delay, :pause_indexing?, to: :migration

    def initialize(version:, name:, filename:)
      @version = version
      @name = name
      @filename = filename
      @migration = nil
    end

    def save!(completed:)
      raise 'Migrations index is not found' unless helper.index_exists?(index_name: index_name)

      data = { completed: completed }.merge(timestamps(completed: completed))

      client.index index: index_name, type: '_doc', id: version, body: data
    end

    def persisted?
      load_from_index.present?
    end

    def load_from_index
      client.get(index: index_name, id: version)
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      nil
    end

    def name_for_key
      name.underscore
    end

    def self.persisted_versions(completed:)
      helper = Gitlab::Elastic::Helper.default
      helper.client
            .search(index: helper.migrations_index_name, body: { query: { term: { completed: completed } } })
            .dig('hits', 'hits')
            .map { |v| v['_id'].to_i }
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      []
    end

    private

    def timestamps(completed:)
      {}.tap do |data|
        existing_data = load_from_index
        data[:started_at] = existing_data&.dig('_source', 'started_at') || Time.now.utc

        data[:completed_at] = Time.now.utc if completed
      end
    end

    def migration
      @migration ||= load_migration
    end

    def load_migration
      require(File.expand_path(filename))
      name.constantize.new version
    end

    def index_name
      helper.migrations_index_name
    end

    def client
      helper.client
    end

    def helper
      Gitlab::Elastic::Helper.default
    end
  end
end
