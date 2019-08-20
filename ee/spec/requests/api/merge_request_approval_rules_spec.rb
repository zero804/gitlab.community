# frozen_string_literal: true

require 'spec_helper'

describe API::MergeRequestApprovalRules do
  set(:user) { create(:user) }
  set(:other_user) { create(:user) }
  set(:project) { create(:project, :public, :repository, creator: user, namespace: user.namespace) }

  describe 'GET /projects/:id/merge_requests/:merge_request_iid/approval_rules' do
    let(:merge_request) { create(:merge_request, author: user, source_project: project, target_project: project) }
    let(:url) { "/projects/#{project.id}/merge_requests/#{merge_request.iid}/approval_rules" }

    context 'user cannot read merge request' do
      before do
        project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)

        get api(url, other_user)
      end

      it 'responds with 403' do
        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'use can read merge request' do
      let(:current_user) { other_user }
      let(:approver) { create(:user) }
      let(:group) { create(:group) }
      let(:source_rule) { nil }
      let(:users) { [approver] }
      let(:groups) { [group] }

      let!(:mr_approval_rule) do
        create(
          :approval_merge_request_rule,
          merge_request: merge_request,
          approval_project_rule: source_rule,
          users: users,
          groups: groups
        )
      end

      before do
        group.add_developer(approver)
        merge_request.approvals.create(user: approver)

        get api(url, current_user)
      end

      it 'matches the response schema' do
        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/merge_request_approval_rules', dir: 'ee')

        rules = json_response

        expect(rules.size).to eq(1)
        expect(rules.first['name']).to eq(mr_approval_rule.name)
        expect(rules.first['approvals_required']).to eq(mr_approval_rule.approvals_required)
        expect(rules.first['contains_hidden_groups']).to eq(false)
        expect(rules.first['rule_type']).to eq(mr_approval_rule.rule_type)
        expect(rules.first['source_rule']).to be_nil
        expect(rules.first['eligible_approvers'].first['id']).to eq(approver.id)
        expect(rules.first['users'].first['id']).to eq(approver.id)
        expect(rules.first['groups'].first['id']).to eq(group.id)
      end

      context 'groups contain private groups' do
        let(:group) { create(:group, :private) }

        context 'current_user cannot see private group' do
          it 'hides private group' do
            rules = json_response

            expect(rules.first['contains_hidden_groups']).to eq(true)
            expect(rules.first['groups']).to be_empty
          end
        end

        context 'current_user can see private group' do
          let(:current_user) { approver }

          it 'shows private group' do
            rules = json_response

            expect(rules.first['contains_hidden_groups']).to eq(false)
            expect(rules.first['groups'].first['id']).to eq(group.id)
          end
        end
      end

      context 'has existing merge request rule that overrides a project-level rule' do
        let(:source_rule) { create(:approval_project_rule, project: project) }

        it 'includes source_rule' do
          expect(json_response.first['source_rule']['approvals_required']).to eq(source_rule.approvals_required)
        end
      end
    end
  end
end
