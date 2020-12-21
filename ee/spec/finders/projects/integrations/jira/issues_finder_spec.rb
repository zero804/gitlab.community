# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Integrations::Jira::IssuesFinder do
  let_it_be(:project, refind: true) { create(:project) }
  let_it_be(:jira_service, reload: true) { create(:jira_service, project: project) }
  let(:params) { {} }
  let(:service) { described_class.new(project, params) }

  before do
    stub_licensed_features(jira_issues_integration: true)
  end

  describe '#execute' do
    subject(:issues) { service.execute }

    context 'when jira service integration does not have project_key' do
      it 'raises error' do
        expect { subject }.to raise_error(Projects::Integrations::Jira::IssuesFinder::IntegrationError, 'Jira project key is not configured')
      end
    end

    context 'when jira service integration is not active' do
      before do
        jira_service.update!(active: false)
      end

      it 'raises error' do
        expect { subject }.to raise_error(Projects::Integrations::Jira::IssuesFinder::IntegrationError, 'Jira service not configured.')
      end
    end

    context 'when jira service integration has project_key' do
      let(:params) { {} }
      let(:client) { double(options: { site: 'https://jira.example.com' }) }

      before do
        jira_service.update!(project_key: 'TEST')
        expect_next_instance_of(Jira::Requests::Issues::ListService) do |instance|
          expect(instance).to receive(:client).at_least(:once).and_return(client)
        end
      end

      context 'when Jira API request fails' do
        before do
          expect(client).to receive(:get).and_raise(Timeout::Error)
        end

        it 'raises error', :aggregate_failures do
          expect { subject }.to raise_error(Projects::Integrations::Jira::IssuesFinder::RequestError)
        end
      end

      context 'when Jira API request succeeds' do
        before do
          expect(client).to receive(:get).and_return(
            {
              "total" => 375,
              "startAt" => 0,
              "issues" => [{ "key" => 'TEST-1' }, { "key" => 'TEST-2' }]
            }
          )
        end

        it 'return service response with issues', :aggregate_failures do
          expect(issues.size).to eq 2
          expect(service.total_count).to eq 375
          expect(issues.map(&:key)).to eq(%w[TEST-1 TEST-2])
        end

        context 'when sorting' do
          shared_examples 'maps sort values' do
            it do
              expect(::Jira::JqlBuilderService).to receive(:new)
                .with(jira_service.project_key, expected_sort_values)
                .and_call_original

              subject
            end
          end

          it_behaves_like 'maps sort values' do
            let(:params) { { sort: 'created_date' } }
            let(:expected_sort_values) { { sort: 'created', sort_direction: 'DESC' } }
          end

          it_behaves_like 'maps sort values' do
            let(:params) { { sort: 'created_desc' } }
            let(:expected_sort_values) { { sort: 'created', sort_direction: 'DESC' } }
          end

          it_behaves_like 'maps sort values' do
            let(:params) { { sort: 'created_asc' } }
            let(:expected_sort_values) { { sort: 'created', sort_direction: 'ASC' } }
          end

          it_behaves_like 'maps sort values' do
            let(:params) { { sort: 'updated_desc' } }
            let(:expected_sort_values) { { sort: 'updated', sort_direction: 'DESC' } }
          end

          it_behaves_like 'maps sort values' do
            let(:params) { { sort: 'updated_asc' } }
            let(:expected_sort_values) { { sort: 'updated', sort_direction: 'ASC' } }
          end

          it_behaves_like 'maps sort values' do
            let(:params) { { sort: 'unknown_sort' } }
            let(:expected_sort_values) { { sort: 'created', sort_direction: 'DESC' } }
          end
        end

        context 'when pagination params used' do
          let(:params) { { page: '10', per_page: '20' } }

          it 'passes them to JqlBuilderService' do
            expect(::Jira::JqlBuilderService).to receive(:new)
              .with(jira_service.project_key, include({ page: '10', per_page: '20' }))
              .and_call_original

            subject
          end
        end
      end
    end

    context 'when jira_issues_integration licensed feature is not available' do
      it 'exits early and returns no issues' do
        stub_licensed_features(jira_issues_integration: false)

        expect(issues.size).to eq 0
        expect(service.total_count).to be_nil
      end
    end
  end
end
