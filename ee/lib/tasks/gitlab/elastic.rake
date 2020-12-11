namespace :gitlab do
  namespace :elastic do
    desc "GitLab | Elasticsearch | Index everything at once"
    task :index do
      # UPDATE_INDEX=true can cause some projects not to be indexed properly if someone were to push a commit to the
      # project before the rake task could get to it, so we set it to `nil` here to avoid that. It doesn't make sense
      # to use this configuration during a full re-index anyways.
      ENV['UPDATE_INDEX'] = nil

      Rake::Task["gitlab:elastic:recreate_index"].invoke
      Rake::Task["gitlab:elastic:clear_index_status"].invoke

      # enable `elasticsearch_indexing` if it isn't
      unless Gitlab::CurrentSettings.elasticsearch_indexing?
        ApplicationSettings::UpdateService.new(
          Gitlab::CurrentSettings.current_application_settings,
          nil,
          { elasticsearch_indexing: true }
        ).execute

        puts "Setting `elasticsearch_indexing` has been enabled."
      end

      Rake::Task["gitlab:elastic:index_projects"].invoke
      Rake::Task["gitlab:elastic:index_snippets"].invoke
    end

    desc "GitLab | Elasticsearch | Index projects in the background"
    task index_projects: :environment do
      print "Enqueuing projects…"

      count = project_id_batches do |ids|
        ::Elastic::ProcessInitialBookkeepingService.backfill_projects!(*Project.find(ids))
        print "."
      end

      marker = count > 0 ? "✔" : "∅"
      puts " #{marker} (#{count})"
    end

    desc "GitLab | ElasticSearch | Check project indexing status"
    task index_projects_status: :environment do
      indexed = IndexStatus.count
      projects = Project.count
      percent = (indexed / projects.to_f) * 100.0

      puts "Indexing is %.2f%% complete (%d/%d projects)" % [percent, indexed, projects]
    end

    desc "GitLab | Elasticsearch | Index all snippets"
    task index_snippets: :environment do
      logger = Logger.new(STDOUT)
      logger.info("Indexing snippets...")

      Snippet.es_import

      logger.info("Indexing snippets... " + "done".color(:green))
    end

    desc "GitLab | Elasticsearch | Create empty indexes and assigns an alias for each"
    task :create_empty_index, [:target_name] => [:environment] do |t, args|
      with_alias = ENV["SKIP_ALIAS"].nil?
      options = {}

      # only create an index at the specified name
      options[:index_name] = args[:target_name] unless with_alias

      helper = Gitlab::Elastic::Helper.new(target_name: args[:target_name])
      index_name = helper.create_empty_index(with_alias: with_alias, options: options)

      # with_alias is used to support interacting with a specific index (such as when reclaiming the production index
      # name when the index was created prior to 13.0). If the `SKIP_ALIAS` environment variable is set,
      # do not create standalone indexes and do not create the migrations index
      if with_alias
        standalone_index_names = helper.create_standalone_indices(options: options)
        standalone_index_names.each do |index_name|
          puts "Index '#{index_name}' has been created.".color(:green)
        end
        helper.create_migrations_index unless helper.index_exists?(index_name: helper.migrations_index_name)
        ::Elastic::DataMigrationService.mark_all_as_completed!
      end

      puts "Index '#{index_name}' has been created.".color(:green)
      puts "Alias '#{helper.target_name}' → '#{index_name}' has been created".color(:green) if with_alias
    end

    desc "GitLab | Elasticsearch | Delete index"
    task :delete_index, [:target_name] => [:environment] do |t, args|
      helper = Gitlab::Elastic::Helper.new(target_name: args[:target_name])

      if helper.delete_index
        puts "Index/alias '#{helper.target_name}' has been deleted".color(:green)
      else
        puts "Index/alias '#{helper.target_name}' was not found".color(:green)
      end
    end

    desc "GitLab | Elasticsearch | Recreate index"
    task :recreate_index, [:target_name] => [:environment] do |t, args|
      Rake::Task["gitlab:elastic:delete_index"].invoke(*args)
      Rake::Task["gitlab:elastic:create_empty_index"].invoke(*args)
    end

    desc "GitLab | Elasticsearch | Zero-downtime cluster reindexing"
    task reindex_cluster: :environment do
      trigger_cluster_reindexing
    end

    desc "GitLab | Elasticsearch | Clear indexing status"
    task clear_index_status: :environment do
      IndexStatus.delete_all
      puts "Index status has been reset".color(:green)
    end

    desc "GitLab | Elasticsearch | Display which projects are not indexed"
    task projects_not_indexed: :environment do
      not_indexed = Project.where.not(id: IndexStatus.select(:project_id).distinct)

      if not_indexed.count == 0
        puts 'All projects are currently indexed'.color(:green)
      else
        display_unindexed(not_indexed)
      end
    end

    desc "GitLab | Elasticsearch | Mark last reindexing job as failed"
    task mark_reindex_failed: :environment do
      if Elastic::ReindexingTask.running?
        Elastic::ReindexingTask.current.failure!
        puts 'Marked the current reindexing job as failed.'.color(:green)
      else
        puts 'Did not find the current running reindexing job.'
      end
    end

    def project_id_batches(&blk)
      relation = Project.all

      unless ENV['UPDATE_INDEX']
        relation = relation.includes(:index_status).where('index_statuses.id IS NULL').references(:index_statuses)
      end

      if ::Gitlab::CurrentSettings.elasticsearch_limit_indexing?
        relation.merge!(::Gitlab::CurrentSettings.elasticsearch_limited_projects)
      end

      count = 0
      relation.in_batches(start: ENV['ID_FROM'], finish: ENV['ID_TO']) do |relation| # rubocop: disable Cop/InBatches
        ids = relation.reorder(:id).pluck(:id)
        yield ids

        count += ids.size
      end

      count
    end

    def trigger_cluster_reindexing
      Elastic::ReindexingTask.create!

      ElasticClusterReindexingCronWorker.perform_async

      puts 'Reindexing job was successfully scheduled'.color(:green)
    rescue PG::UniqueViolation, ActiveRecord::RecordNotUnique
      puts 'There is another task in progress. Please wait for it to finish.'.color(:red)
    end

    def display_unindexed(projects)
      arr = if projects.count < 500 || ENV['SHOW_ALL']
              projects
            else
              projects[1..500]
            end

      arr.each do |p|
        puts "Project '#{p.full_path}' (ID: #{p.id}) isn't indexed.".color(:red)
      end

      puts "#{arr.count} out of #{projects.count} non-indexed projects shown."
    end
  end
end
