# frozen_string_literal: true

module Resolvers
  module Projects
    class JiraProjectsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::Projects::Services::JiraProjectType.connection_type, null: true
      authorize :admin_project

      argument :name,
               GraphQL::STRING_TYPE,
               required: false,
               description: 'Project name or key'

      def resolve(name: nil, **args)
        authorize!(project)

        response = jira_projects(name: name)

        if response.success?
          projects_array = response.payload[:projects]

          GraphQL::Pagination::ArrayConnection.new(
            projects_array,
            # override default max_page_size to whatever the size of the response is,
            # see https://gitlab.com/gitlab-org/gitlab/-/issues/231394
            **args.merge({ max_page_size: projects_array.size })
          )
        else
          raise Gitlab::Graphql::Errors::BaseError, response.message
        end
      end

      private

      alias_method :jira_service, :object

      def project
        jira_service&.project
      end

      def jira_projects(name:)
        args = { query: name }.compact

        Jira::Requests::Projects::ListService.new(project.jira_service, args).execute
      end
    end
  end
end
