# frozen_string_literal: true

class CopyIssuesServiceDeskReplyToToIssueEmailParticipants < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    gitlab_support_bot_id = execute("SELECT COALESCE((SELECT id FROM users WHERE username = 'support-bot'), -1) id").first["id"]

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
      WHERE author_id = #{gitlab_support_bot_id}
      ON CONFLICT (issue_id, email) DO NOTHING
    SQL
  end

  def down
    execute <<~SQL
      DELETE FROM issue_email_participants
    SQL
  end
end
