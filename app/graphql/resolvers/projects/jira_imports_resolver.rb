# frozen_string_literal: true

module Resolvers
  module Projects
    class JiraImportsResolver < BaseResolver
      prepend ::ManualAuthorization
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::JiraImportType.connection_type, null: true

      alias_method :project, :object

      def resolve(**args)
        authorize!(project)

        project.jira_imports
      end

      def authorized_resource?(project)
        context[:current_user].present? && Ability.allowed?(context[:current_user], :read_project, project)
      end
    end
  end
end
