# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::BaseResolver do
  include GraphqlHelpers

  let(:resolver) do
    Class.new(described_class) do
      def resolve(**args)
        [args, args]
      end
    end
  end

  describe '.single' do
    it 'returns a subclass from the resolver' do
      expect(resolver.single.superclass).to eq(resolver)
    end

    it 'returns the same subclass every time' do
      expect(resolver.single.object_id).to eq(resolver.single.object_id)
    end

    it 'returns a resolver that gives the first result from the original resolver' do
      result = resolve(resolver.single, args: { test: 1 })

      expect(result).to eq(test: 1)
    end
  end

  it 'increases complexity based on arguments' do
    field = Types::BaseField.new(name: 'test', type: GraphQL::STRING_TYPE, resolver_class: described_class, null: false, max_page_size: 1)

    expect(field.to_graphql.complexity.call({}, { sort: 'foo' }, 1)).to eq 3
    expect(field.to_graphql.complexity.call({}, { search: 'foo' }, 1)).to eq 7
  end

  it 'does not increase complexity when filtering by iids' do
    field = Types::BaseField.new(name: 'test', type: GraphQL::STRING_TYPE, resolver_class: described_class, null: false, max_page_size: 100)

    expect(field.to_graphql.complexity.call({}, { sort: 'foo' }, 1)).to eq 6
    expect(field.to_graphql.complexity.call({}, { sort: 'foo', iid: 1 }, 1)).to eq 3
    expect(field.to_graphql.complexity.call({}, { sort: 'foo', iids: [1, 2, 3] }, 1)).to eq 3
  end
end
