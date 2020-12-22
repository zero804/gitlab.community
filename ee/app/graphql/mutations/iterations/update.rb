# frozen_string_literal: true

module Mutations
  module Iterations
    class Update < BaseMutation
      include Mutations::ResolvesGroup
      include ResolvesProject

      graphql_name 'UpdateIteration'

      authorize :admin_iteration

      field :iteration,
            Types::IterationType,
            null: true,
            description: 'Updated iteration.'

      argument :group_path, GraphQL::ID_TYPE,
               required: true,
               description: 'Group of the iteration.'

      # rubocop:disable Graphql/IDType
      argument :id,
               GraphQL::ID_TYPE,
               required: true,
               description: 'Global ID of the iteration.'
      # rubocop:enable Graphql/IDType

      argument :title,
               GraphQL::STRING_TYPE,
               required: false,
               description: 'Title of the iteration.'

      argument :description,
               GraphQL::STRING_TYPE,
               required: false,
               description: 'Description of the iteration.'

      argument :start_date,
               GraphQL::STRING_TYPE,
               required: false,
               description: 'Start date of the iteration.'

      argument :due_date,
               GraphQL::STRING_TYPE,
               required: false,
               description: 'End date of the iteration.'

      def resolve(args)
        validate_arguments!(args)
        args[:id] = id_from_args(args)

        parent = resolve_group(full_path: args[:group_path]).try(:sync)
        iteration = authorized_find!(parent: parent, id: args[:id])

        response = ::Iterations::UpdateService.new(parent, current_user, args).execute(iteration)

        response_object = response.payload[:iteration] if response.success?
        response_errors = response.error? ? (response.payload[:errors] || response.message) : []

        {
            iteration: response_object,
            errors: response_errors
        }
      end

      private

      def find_object(parent:, id:)
        ::Resolvers::IterationsResolver.new(object: parent, context: context, field: nil)
          .resolve(id: id).first
      end

      def validate_arguments!(args)
        raise Gitlab::Graphql::Errors::ArgumentError, 'The list of iteration attributes is empty' if args.except(:group_path, :id).empty?
      end

      # Originally accepted a raw model id. Now accept a gid, but allow a raw id
      # for backward compatibility
      def id_from_args(args)
        GitlabSchema.parse_gid(args[:id], expected_type: ::Iteration)
      rescue Gitlab::Graphql::Errors::ArgumentError
        ::Gitlab::GlobalId.as_global_id(args[:id].to_i, model_name: 'Iteration')
      end
    end
  end
end
