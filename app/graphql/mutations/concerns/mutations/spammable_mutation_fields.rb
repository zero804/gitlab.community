# frozen_string_literal: true

module Mutations
  module SpammableMutationFields
    extend ActiveSupport::Concern

    included do
      field :spam,
            GraphQL::BOOLEAN_TYPE,
            null: true,
            description: 'Indicates whether the operation returns a record detected as spam'
    end

    def with_spam_params(&block)
      yield.merge({ api: true, request: context[:request] })
    end

    def with_spam_fields(spammable, &block)
      { spam: spammable.spam? }.merge!(yield)
    end
  end
end
