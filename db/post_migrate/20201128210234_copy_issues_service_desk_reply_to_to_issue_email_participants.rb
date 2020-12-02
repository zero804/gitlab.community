# frozen_string_literal: true

class CopyIssuesServiceDeskReplyToToIssueEmailParticipants < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    execute <<~SQL.squish
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
      ON CONFLICT (issue_id, email) DO NOTHING
    SQL
  end

  def down
    # no-op
  end
end
