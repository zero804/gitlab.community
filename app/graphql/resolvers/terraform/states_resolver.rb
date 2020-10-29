# frozen_string_literal: true

module Resolvers
  module Terraform
    class StatesResolver < BaseResolver
      type Types::Terraform::StateType, null: true

      alias_method :project, :object

      def resolve(**args)
        ::Terraform::StatesFinder.new(project, current_user).execute
      end
    end
  end
end
