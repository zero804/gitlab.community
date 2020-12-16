# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::IncidentManagement::OncallShiftsResolver do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:rotation) { create(:incident_management_oncall_rotation, :with_participant) }
  let_it_be(:project) { rotation.project }
  let(:args) { { starts_at: rotation.starts_at, ends_at: rotation.starts_at + rotation.shift_duration } }

  subject(:shifts) { sync(resolve_oncall_shifts(args)) }

  before do
    stub_licensed_features(oncall_schedules: true)
    project.add_reporter(current_user)
  end

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::IncidentManagement::OncallShiftType.connection_type)
  end

  it 'returns on-call schedules' do
    expect(shifts.length).to eq(1)
    expect(shifts.first).to be_a(::IncidentManagement::OncallShift)
    expect(shifts.first).to have_attributes(rotation: rotation, **args)
  end

  context 'when an error occurs while finding shifts' do
    subject(:shifts) { sync(resolve_oncall_shifts(args, current_user: nil)) }

    it 'raises ResourceNotAvailable error' do
      expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end
  end

  private

  def resolve_oncall_shifts(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: rotation, args: args, ctx: context)
  end
end
