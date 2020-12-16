# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting Incident Management on-call shifts' do
  include GraphqlHelpers

  let_it_be(:participant) { create(:incident_management_oncall_participant, :with_developer_access) }
  let_it_be(:rotation) { participant.rotation }
  let_it_be(:project) { rotation.project }
  let_it_be(:current_user) { participant.user }

  let(:starts_at) { rotation.starts_at }
  let(:ends_at) { rotation.starts_at + rotation.shift_duration }
  let(:params) { { starts_at: starts_at.iso8601, ends_at: ends_at.iso8601 } }

  let(:shift_fields) do
    <<~QUERY
      nodes {
        participant { id }
        endsAt
        startsAt
      }
    QUERY
  end

  let(:schedule_fields) do
    <<~QUERY
      nodes {
        rotations {
          nodes {
            #{query_graphql_field('shifts', params, shift_fields)}
          }
        }
      }
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('incidentManagementOncallSchedules', {}, schedule_fields)
    )
  end

  let(:shifts) do
    graphql_data
      .dig('project', 'incidentManagementOncallSchedules', 'nodes').first
      .dig('rotations', 'nodes').first
      .dig('shifts', 'nodes')
  end

  before do
    stub_licensed_features(oncall_schedules: true)
    post_graphql(query, current_user: current_user)
  end

  it_behaves_like 'a working graphql query'

  it 'returns the correct properties of the on-call shifts' do
    expect(shifts.first).to include(
      'participant' => { 'id' => participant.to_global_id.to_s },
      'startsAt' => params[:starts_at],
      'endsAt' => params[:ends_at]
    )
  end

  context "without required argument starts_at" do
    let(:params) { { ends_at: ends_at.iso8601 } }

    it 'raises an exception' do
      expect(graphql_errors).to include(a_hash_including('message' => "Field 'shifts' is missing required arguments: startsAt"))
    end
  end

  context "without required argument ends_at" do
    let(:params) { { starts_at: starts_at.iso8601 } }

    it 'raises an exception' do
      expect(graphql_errors).to include(a_hash_including('message' => "Field 'shifts' is missing required arguments: endsAt"))
    end
  end
end
