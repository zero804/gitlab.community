# frozen_string_literal: true

module IncidentManagement
  module OncallScheduleHelper
    def oncall_schedule_data(project)
      {
        'project-path' => project.full_path,
        'empty-oncall-schedules-svg-path' => image_path('illustrations/empty-state/empty-on-call.svg'),
        'timezones' => timezone_data(format: :full).to_json
      }
    end
  end
end
