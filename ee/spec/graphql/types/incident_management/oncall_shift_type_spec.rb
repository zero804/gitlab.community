# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['IncidentManagementOncallShift'] do
  specify { expect(described_class.graphql_name).to eq('IncidentManagementOncallShift') }

  specify { expect(described_class).to require_graphql_authorizations(:read_incident_management_oncall_schedule) }

  it 'exposes the expected fields' do
    expected_fields = %i[
      participant
      starts_at
      ends_at
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
