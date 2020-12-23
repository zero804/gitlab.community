# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::IncidentManagement::OncallShifts::ReadService do
  let_it_be_with_refind(:rotation) { create(:incident_management_oncall_rotation, :with_participant) }
  let_it_be(:project) { rotation.project }
  let_it_be(:user_with_permissions) { create(:user) }
  let_it_be(:user_without_permissions) { create(:user) }
  let_it_be(:current_user) { user_with_permissions }

  let(:params) { { starts_at: rotation.starts_at + 15.minutes, ends_at: rotation.starts_at + 3.weeks } }
  let(:service) { described_class.new(rotation, current_user, params) }

  before_all do
    project.add_reporter(user_with_permissions)
  end

  before do
    stub_licensed_features(oncall_schedules: true)
  end

  describe '#execute' do
    shared_examples 'error response' do |message|
      it 'has an informative message' do
        expect(execute).to be_error
        expect(execute.message).to eq(message)
      end
    end

    subject(:execute) { service.execute }

    context 'when the current_user is anonymous' do
      let(:current_user) { nil }

      it_behaves_like 'error response', 'You have insufficient permissions to view shifts for this rotation'
    end

    context 'when the current_user does not have permissions to create on-call schedules' do
      let(:current_user) { user_without_permissions }

      it_behaves_like 'error response', 'You have insufficient permissions to view shifts for this rotation'
    end

    context 'when feature is not available' do
      before do
        stub_licensed_features(oncall_schedules: false)
      end

      it_behaves_like 'error response', 'Your license does not support on-call rotations'
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(oncall_schedules_mvc: false)
      end

      it_behaves_like 'error response', 'Your license does not support on-call rotations'
    end

    context 'with valid params' do
      it 'successfully returns a sorted collection of IncidentManagement::OncallShifts' do
        expect(execute).to be_success

        shifts = execute.payload[:shifts]

        expect(shifts).to all( be_a(::IncidentManagement::OncallShift) )
        expect(shifts).to all( be_valid )
        expect(shifts.sort_by(&:starts_at)).to eq(shifts)
        expect(shifts.first.starts_at).to be <= params[:starts_at]
        expect(shifts.last.ends_at).to be >= params[:ends_at]
      end
    end
  end
end
