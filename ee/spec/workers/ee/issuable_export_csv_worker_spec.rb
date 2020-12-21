# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuableExportCsvWorker do
  let(:user) { create(:user) }
  let(:project) { create(:project, creator: user) }
  let(:params) { {} }

  subject { described_class.new.perform(issuable_type, user.id, project.id, params) }

  context 'when issuable type is Requirement' do
    let(:issuable_type) { :requirement }

    it 'emails a CSV' do
      expect { subject }.to change(ActionMailer::Base.deliveries, :size).by(1)
    end

    it 'calls the Requirements export service' do
      expect(RequirementsManagement::ExportCsvService).to receive(:new).with(anything, project).once.and_call_original

      subject
    end

    it 'calls the Requirements finder' do
      expect(RequirementsManagement::RequirementsFinder).to receive(:new).once.and_call_original

      subject
    end
  end
end
