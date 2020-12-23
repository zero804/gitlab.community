# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::OncallRotation do
  let_it_be(:schedule) { create(:incident_management_oncall_schedule) }

  describe '.associations' do
    it { is_expected.to belong_to(:schedule) }
    it { is_expected.to have_many(:participants) }
    it { is_expected.to have_many(:users).through(:participants) }
    it { is_expected.to have_many(:shifts) }
  end

  describe '.validations' do
    subject { build(:incident_management_oncall_rotation, schedule: schedule, name: 'Test rotation') }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(200) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:oncall_schedule_id) }
    it { is_expected.to validate_presence_of(:starts_at) }
    it { is_expected.to validate_presence_of(:length) }
    it { is_expected.to validate_numericality_of(:length) }
    it { is_expected.to validate_presence_of(:length_unit) }

    context 'when the oncall rotation with the same name exists' do
      before do
        create(:incident_management_oncall_rotation, schedule: schedule, name: 'Test rotation')
      end

      it 'has validation errors' do
        expect(subject).to be_invalid
        expect(subject.errors.full_messages.to_sentence).to eq('Name has already been taken')
      end
    end
  end
end
