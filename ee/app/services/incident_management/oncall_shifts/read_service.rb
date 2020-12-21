# frozen_string_literal: true

module IncidentManagement
  module OncallShifts
    class ReadService
      # @param rotation [IncidentManagement::OncallRotation]
      # @param current_user [User]
      # @param params [Hash<Symbol,Any>]
      # @option params - starts_at [Time]
      # @option params - ends_at [Time]
      # @option params - include_persisted [Bool]
      def initialize(rotation, current_user, starts_at:, ends_at:, include_persisted: true)
        @rotation = rotation
        @current_user = current_user
        @starts_at = starts_at
        @ends_at = ends_at
        @include_persisted = include_persisted
      end

      def execute
        return error_no_license unless available?
        return error_no_permissions unless allowed?

        # Get persisted shifts, and generate shifts for the range
        @persisted_shifts = rotation.shifts.for_timeframe(starts_at, ends_at)
        @generated_shifts = generate_shifts # TODO can we just exclude the dates here?

        # Remove the persisted dates from the generated ones
        @generated_shifts = remove_persisted_shifts

        if include_persisted
          @generated_shifts = combine_persisted_and_generated_shifts
        end

        success(
          generated_shifts
        )
      end

      private

      attr_reader :rotation, :current_user, :starts_at, :ends_at, :include_persisted, :generated_shifts, :persisted_shifts

      def generate_shifts
        ::IncidentManagement::OncallShiftGenerator
          .new(rotation)
          .for_timeframe(starts_at: starts_at, ends_at: ends_at)
      end

      def remove_persisted_shifts
        generated_shifts.reject do |shift|
          persisted_shifts.any? { |persisted| persisted.starts_at == shift.starts_at && persisted.ends_at == shift.ends_at }
        end
      end

      def combine_persisted_and_generated_shifts
        (generated_shifts << persisted_shifts).flatten.sort_by(&:starts_at)
      end

      def available?
        ::Gitlab::IncidentManagement.oncall_schedules_available?(rotation.project)
      end

      def allowed?
        Ability.allowed?(current_user, :read_incident_management_oncall_schedule, rotation)
      end

      def error(message)
        ServiceResponse.error(message: message)
      end

      def success(shifts)
        ServiceResponse.success(payload: { shifts: shifts })
      end

      def error_no_permissions
        error(_('You have insufficient permissions to view shifts for this rotation'))
      end

      def error_no_license
        error(_('Your license does not support on-call rotations'))
      end
    end
  end
end
