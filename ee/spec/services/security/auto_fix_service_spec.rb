# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::AutoFixService do
  describe '#execute' do
    subject(:execute_service) { service.execute(ids) }

    let(:service) { described_class.new(project) }
    let(:project) { create(:project, :custom_repo, files: { 'yarn.lock' => yarn_lock_content }) }
    let_it_be(:pipeline) { create(:ee_ci_pipeline) }
    let_it_be(:vulnerability_with_rem) { create(:vulnerabilities_finding_with_remediation, :yarn_remediation, report_type: :dependency_scanning, summary: 'Test remediation') }

    let(:remediations_folder) { Rails.root.join('ee/spec/fixtures/security_reports/remediations') }
    let(:yarn_lock_content) do
      File.read(
        File.join(remediations_folder, "yarn.lock")
      )
    end

    let(:remediation_diff) do
      Base64.encode64(
        File.read(
          File.join(remediations_folder, "remediation.patch")
        )
      )
    end

    context 'with enabled auto-fix' do
      let!(:setting) { create(:project_security_setting, project: project) }

      context 'when remediations exist' do
        let(:ids) { [vulnerability_with_rem.id] }

        it 'creates MR' do
          expect(MergeRequest.count).to eq(0)
          expect(Vulnerabilities::Feedback.count).to eq(0)

          execute_service

          expect(Vulnerabilities::Feedback.count).to eq(1)
          expect(MergeRequest.count).to eq(1)
          expect(MergeRequest.last.title).to eq('Resolve vulnerability: Cipher with no integrity')
        end

        context 'when running second time' do
          it 'does not create second merge request' do
            execute_service

            expect(Vulnerabilities::Feedback.count).to eq(1)
            expect(MergeRequest.count).to eq(1)

            execute_service

            expect(Vulnerabilities::Feedback.count).to eq(1)
            expect(MergeRequest.count).to eq(1)
          end
        end
      end

      context 'without remediations' do
        let(:vulnerability) { create(:vulnerabilities_finding, report_type: :dependency_scanning) }
        let(:ids) { [vulnerability.id] }

        it 'does not create merge request' do
          execute_service

          expect(Vulnerabilities::Feedback.count).to eq(0)
          expect(MergeRequest.count).to eq(0)

        end
      end
    end
  end
end
