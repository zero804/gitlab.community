# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).pipelines' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:user) { create(:user) }

  describe '.jobs' do
    let(:first_n) { var('Int') }
    let(:query_path) do
      [
        [:project, { full_path: project.full_path }],
        [:pipelines, { first: first_n }],
        [:nodes],
        [:jobs],
        [:nodes]
      ]
    end

    let(:query) do
      with_signature([first_n], query_graphql_path(query_path, :name))
    end

    before_all do
      pipeline = create(:ci_pipeline, project: project)
      create(:ci_build, pipeline: pipeline, name: 'Job 1')
      pipeline = create(:ci_pipeline, project: project)
      create(:ci_build, pipeline: pipeline, name: 'Job 2')
    end

    it 'limits the results' do
      post_graphql(query, current_user: user, variables: first_n.with(1))

      expect(graphql_data_at(*query_path.map(&:first))).to contain_exactly a_hash_including(
        'name' => 'Job 2'
      )
    end

    it 'fetches all results' do
      post_graphql(query, current_user: user)

      expect(graphql_data_at(*query_path.map(&:first))).to contain_exactly(
        a_hash_including('name' => 'Job 1'),
        a_hash_including('name' => 'Job 2')
      )
    end

    it 'fetches the jobs without an N+1' do
      first_user = create(:personal_access_token).user
      second_user = create(:personal_access_token).user

      control_count = ActiveRecord::QueryRecorder.new do
        post_graphql(query, current_user: first_user, variables: first_n.with(1))
      end

      expect do
        post_graphql(query, current_user: second_user)
      end.not_to exceed_query_limit(control_count)
    end
  end

  describe '.jobs(securityReportTypes)' do
    let_it_be(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            pipelines {
              nodes {
                jobs(securityReportTypes: [SAST]) {
                  nodes {
                    name
                  }
                }
              }
            }
          }
        }
      )
    end

    it 'fetches the jobs matching the report type filter' do
      pipeline = create(:ci_pipeline, project: project)
      create(:ci_build, :dast, name: 'DAST Job 1', pipeline: pipeline)
      create(:ci_build, :sast, name: 'SAST Job 1', pipeline: pipeline)

      post_graphql(query, current_user: user)

      expect(response).to have_gitlab_http_status(:ok)

      pipelines_data = graphql_data.dig('project', 'pipelines', 'nodes')

      job_names = pipelines_data.map do |pipeline_data|
        jobs_data = pipeline_data.dig('jobs', 'nodes')
        jobs_data.map { |job_data| job_data['name'] }
      end.flatten

      expect(job_names).to contain_exactly('SAST Job 1')
    end
  end

  describe 'upstream' do
    let_it_be(:pipeline) { create(:ci_pipeline, project: project, user: user) }
    let_it_be(:upstream_project) { create(:project, :repository, :public) }
    let_it_be(:upstream_pipeline) { create(:ci_pipeline, project: upstream_project, user: user) }
    let(:upstream_pipelines_graphql_data) { graphql_data.dig(*%w[project pipelines nodes]).first['upstream'] }

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            pipelines {
              nodes {
                upstream {
                  iid
                }
              }
            }
          }
        }
      )
    end

    before do
      create(:ci_sources_pipeline, source_pipeline: upstream_pipeline, pipeline: pipeline )

      post_graphql(query, current_user: user)
    end

    it_behaves_like 'a working graphql query'

    it 'returns the upstream pipeline of a pipeline' do
      expect(upstream_pipelines_graphql_data['iid'].to_i).to eq(upstream_pipeline.iid)
    end

    context 'when fetching the upstream pipeline from the pipeline' do
      it 'avoids N+1 queries' do
        first_user = create(:user)
        second_user = create(:user)

        control_count = ActiveRecord::QueryRecorder.new do
          post_graphql(query, current_user: first_user)
        end

        pipeline_2 = create(:ci_pipeline, project: project, user: user)
        upstream_pipeline_2 = create(:ci_pipeline, project: upstream_project, user: user)
        create(:ci_sources_pipeline, source_pipeline: upstream_pipeline_2, pipeline: pipeline_2 )
        pipeline_3 = create(:ci_pipeline, project: project, user: user)
        upstream_pipeline_3 = create(:ci_pipeline, project: upstream_project, user: user)
        create(:ci_sources_pipeline, source_pipeline: upstream_pipeline_3, pipeline: pipeline_3 )

        expect do
          post_graphql(query, current_user: second_user)
        end.not_to exceed_query_limit(control_count)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe 'downstream' do
    let_it_be(:pipeline) { create(:ci_pipeline, project: project, user: user) }
    let(:pipeline_2) { create(:ci_pipeline, project: project, user: user) }

    let_it_be(:downstream_project) { create(:project, :repository, :public) }
    let_it_be(:downstream_pipeline_a) { create(:ci_pipeline, project: downstream_project, user: user) }
    let_it_be(:downstream_pipeline_b) { create(:ci_pipeline, project: downstream_project, user: user) }

    let(:pipelines_graphql_data) { graphql_data.dig(*%w[project pipelines nodes]) }

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            pipelines {
              nodes {
                downstream {
                  nodes {
                    iid
                  }
                }
              }
            }
          }
        }
      )
    end

    before do
      create(:ci_sources_pipeline, source_pipeline: pipeline, pipeline: downstream_pipeline_a)
      create(:ci_sources_pipeline, source_pipeline: pipeline_2, pipeline: downstream_pipeline_b)

      post_graphql(query, current_user: user)
    end

    it_behaves_like 'a working graphql query'

    it 'returns the downstream pipelines of a pipeline' do
      downstream_pipelines_graphql_data = pipelines_graphql_data.map { |pip| pip['downstream']['nodes'] }.flatten

      expect(
        downstream_pipelines_graphql_data.map { |pip| pip['iid'].to_i }
      ).to contain_exactly(downstream_pipeline_a.iid, downstream_pipeline_b.iid)
    end

    context 'when fetching the downstream pipelines from the pipeline' do
      it 'avoids N+1 queries' do
        first_user = create(:user)
        second_user = create(:user)

        control_count = ActiveRecord::QueryRecorder.new do
          post_graphql(query, current_user: first_user)
        end

        downstream_pipeline_2a = create(:ci_pipeline, project: downstream_project, user: user)
        create(:ci_sources_pipeline, source_pipeline: pipeline, pipeline: downstream_pipeline_2a)
        downsteam_pipeline_3a = create(:ci_pipeline, project: downstream_project, user: user)
        create(:ci_sources_pipeline, source_pipeline: pipeline, pipeline: downsteam_pipeline_3a)

        downstream_pipeline_2b = create(:ci_pipeline, project: downstream_project, user: user)
        create(:ci_sources_pipeline, source_pipeline: pipeline_2, pipeline: downstream_pipeline_2b)
        downsteam_pipeline_3b = create(:ci_pipeline, project: downstream_project, user: first_user)
        create(:ci_sources_pipeline, source_pipeline: pipeline_2, pipeline: downsteam_pipeline_3b)

        expect do
          post_graphql(query, current_user: second_user)
        end.not_to exceed_query_limit(control_count)
      end
    end
  end
end
