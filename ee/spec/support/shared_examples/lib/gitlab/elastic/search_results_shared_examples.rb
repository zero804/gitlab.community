# frozen_string_literal: true

RSpec.shared_examples 'does not hit Elasticsearch twice for objects and counts' do |scopes|
  scopes.each do |scope|
    context "for scope #{scope}", :elastic, :request_store do
      it 'makes 1 Elasticsearch query' do
        # We want to warm the cache for checking migrations have run since we
        # don't want to count these requests as searches
        allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
        warm_elasticsearch_migrations_cache!
        ::Gitlab::SafeRequestStore.clear!

        results.objects(scope)
        results.public_send("#{scope}_count")

        expect(::Gitlab::Instrumentation::ElasticsearchTransport.get_request_count).to eq(1)
      end
    end
  end
end
