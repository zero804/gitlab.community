# frozen_string_literal: true

module Resolvers
  module IncidentManagement
    class OncallShiftsResolver < BaseResolver
      alias_method :rotation, :synchronized_object

      type Types::IncidentManagement::OncallShiftType.connection_type, null: true

      argument :starts_at,
               ::Types::TimeType,
               required: true,
               description: 'Start of timeframe.'

      argument :ends_at,
               ::Types::TimeType,
               required: true,
               description: 'End of timeframe.'

      def resolve(starts_at:, ends_at:)
        result = ::IncidentManagement::OncallShifts::ReadService.new(
          rotation,
          current_user,
          starts_at: starts_at,
          ends_at: ends_at
        ).execute

        raise Gitlab::Graphql::Errors::ResourceNotAvailable, result.errors.join(', ') if result.error?

        result.payload[:shifts]
      end
    end
  end
end
