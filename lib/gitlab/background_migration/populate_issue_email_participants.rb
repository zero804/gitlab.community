# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Class to migrate service_desk_reply_to email addresses to issue_email_participants
    class PopulateIssueEmailParticipants
      def perform(start_id, stop_id)
        ActiveRecord::Base.connection.execute <<~SQL.squish
          INSERT INTO issue_email_participants (issue_id,
            created_at,
            updated_at,
            email)
          SELECT id,
            created_at,
            updated_at,
            service_desk_reply_to
          FROM issues
          WHERE service_desk_reply_to IS NOT NULL
          AND issues.id BETWEEN #{start_id} AND #{stop_id}
          ON CONFLICT (issue_id, email) DO NOTHING
        SQL
      end
    end
  end
end
