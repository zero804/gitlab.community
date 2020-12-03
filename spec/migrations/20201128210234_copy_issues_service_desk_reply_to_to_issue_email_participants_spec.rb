# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20201128210234_copy_issues_service_desk_reply_to_to_issue_email_participants.rb')

RSpec.describe CopyIssuesServiceDeskReplyToToIssueEmailParticipants do
  let!(:namespace) { table(:namespaces).create!(name: 'namespace', path: 'namespace') }
  let!(:project) { table(:projects).create!(id: 1, namespace_id: namespace.id) }
  let!(:issue1) { table(:issues).create!(project_id: project.id, service_desk_reply_to: "a@gitlab.com") }
  let!(:issue2) { table(:issues).create!(project_id: project.id, service_desk_reply_to: "b@gitlab.com") }
  let!(:issue3) { table(:issues).create!(project_id: project.id) }
  let(:issue_email_participants) { table(:issue_email_participants) }

  describe '#up' do
    it 'migrates email addresses from service desk issues', :aggregate_failures do
      expect { migrate! }.to change { issue_email_participants.count }.by(2)

      expect(issue_email_participants.find_by(issue_id: issue1.id).email).to eq("a@gitlab.com")
      expect(issue_email_participants.find_by(issue_id: issue2.id).email).to eq("b@gitlab.com")
      expect(issue_email_participants.find_by(issue_id: issue3.id)).to be_nil
    end

    it 'ignores records conflicting on issue_id and email' do
      issue_email_participants.create!(issue_id: issue1.id, email: issue1.service_desk_reply_to)

      expect { migrate! }.to change { issue_email_participants.count }.by(1)
    end
  end
end
