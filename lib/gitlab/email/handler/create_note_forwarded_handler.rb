# frozen_string_literal: true

require 'gitlab/email/handler/base_handler'

# handles note creation emails when forwarded by an authorized user.  Attachments
# are allowed, but currently quoted material is stripped, just like normal replies.
# Supports these formats:
#   incoming+gitlab-org-gitlab-ce-20-Author_Token12345678-issue-34@incoming.gitlab.com
module Gitlab
  module Email
    module Handler
      class CreateNoteForwardedHandler < BaseHandler
        include ReplyProcessing

        attr_reader :issueable_iid

        HANDLER_REGEX = /\A#{HANDLER_ACTION_BASE_REGEX}-(?<incoming_email_token>.+)-issue-(?<issueable_iid>\d+)\z/.freeze

        def initialize(mail, mail_key)
          super(mail, mail_key)

          if (matched = HANDLER_REGEX.match(mail_key.to_s))
            @project_slug         = matched[:project_slug]
            @project_id           = matched[:project_id]&.to_i
            @incoming_email_token = matched[:incoming_email_token]
            @issueable_iid        = matched[:issueable_iid]&.to_i
          end
        end

        def can_handle?
          incoming_email_token && project_id && issueable_iid
        end

        def execute
          raise ProjectNotFound unless project

          validate_permission!(:create_note)

          raise NoteableNotFoundError unless noteable
          raise EmptyEmailError if message_including_reply.blank?

          verify_record!(
            record: create_note,
            invalid_exception: InvalidNoteError,
            record_name: 'comment')
        end

        def metrics_event
          :receive_email_create_note_forwarded
        end

        def noteable
          return unless issueable_iid

          @noteable ||= project&.issues&.find_by_iid(issueable_iid)
        end

        private

        # rubocop: disable CodeReuse/ActiveRecord
        def author
          @author ||= User.find_by(incoming_email_token: incoming_email_token)
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def create_note
          Notes::CreateService.new(project, author, note_params).execute
        end

        def note_params
          {
            noteable_type: noteable.class.to_s,
            noteable_id: noteable.id,
            note: message_including_reply
          }
        end
      end
    end
  end
end
