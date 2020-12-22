# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApprovalRuleLike do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:group1) { create(:group) }
  let(:group2) { create(:group) }

  let(:merge_request) { create(:merge_request) }

  shared_examples 'approval rule like' do
    describe '#approvers' do
      let(:group1_user) { create(:user) }
      let(:group2_user) { create(:user) }

      before do
        subject.users << user1
        subject.users << user2
        subject.groups << group1
        subject.groups << group2

        group1.add_guest(group1_user)
        group2.add_guest(group2_user)
      end

      shared_examples 'approvers contains the right users' do
        it 'contains users as direct members and group members' do
          expect(subject.approvers).to contain_exactly(user1, user2, group1_user, group2_user)
        end
      end

      it_behaves_like 'approvers contains the right users'

      context 'when the user relations are already loaded' do
        before do
          subject.users
          subject.group_users
        end

        it_behaves_like 'approvers contains the right users'
      end

      context 'when user is both a direct member and a group member' do
        before do
          group1.add_guest(user1)
          group2.add_guest(user2)
        end

        it 'contains only unique users' do
          expect(subject.approvers).to contain_exactly(user1, user2, group1_user, group2_user)
        end
      end
    end

    describe 'validation' do
      context 'when value is too big' do
        it 'is invalid' do
          subject.approvals_required = described_class::APPROVALS_REQUIRED_MAX + 1

          expect(subject).to be_invalid
          expect(subject.errors.key?(:approvals_required)).to eq(true)
        end
      end

      context 'when value is within limit' do
        it 'is valid' do
          subject.approvals_required = described_class::APPROVALS_REQUIRED_MAX

          expect(subject).to be_valid
        end
      end
    end
  end

  context 'MergeRequest' do
    subject { create(:approval_merge_request_rule, merge_request: merge_request) }

    it_behaves_like 'approval rule like'

    describe '#overridden?' do
      it 'returns false' do
        expect(subject.overridden?).to be_falsy
      end

      context 'when rule has source rule' do
        let(:source_rule) do
          create(
            :approval_project_rule,
            project: merge_request.target_project,
            name: 'Source Rule',
            approvals_required: 2,
            users: [user1, user2],
            groups: [group1, group2]
          )
        end

        before do
          subject.update!(approval_project_rule: source_rule)
        end

        context 'and any attributes differ from source rule' do
          shared_examples_for 'overridden rule' do
            it 'returns true' do
              expect(subject.overridden?).to be_truthy
            end
          end

          context 'name' do
            before do
              subject.update!(name: 'Overridden Rule')
            end

            it_behaves_like 'overridden rule'
          end

          context 'approvals_required' do
            before do
              subject.update!(approvals_required: 1)
            end

            it_behaves_like 'overridden rule'
          end

          context 'users' do
            before do
              subject.update!(users: [user1])
            end

            it_behaves_like 'overridden rule'
          end

          context 'groups' do
            before do
              subject.update!(groups: [group1])
            end

            it_behaves_like 'overridden rule'
          end
        end

        context 'and no changes made to attributes' do
          before do
            subject.update!(
              name: source_rule.name,
              approvals_required: source_rule.approvals_required,
              users: source_rule.users,
              groups: source_rule.groups
            )
          end

          it 'returns false' do
            expect(subject.overridden?).to be_falsy
          end
        end
      end
    end
  end

  context 'Project' do
    subject { create(:approval_project_rule) }

    it_behaves_like 'approval rule like'

    describe '#overridden?' do
      it 'returns false' do
        expect(subject.overridden?).to be_falsy
      end
    end
  end

  describe '.group_users' do
    subject { create(:approval_project_rule) }

    it 'returns distinct users' do
      group1.add_guest(user1)
      group2.add_guest(user1)
      subject.groups = [group1, group2]

      expect(subject.group_users).to eq([user1])
    end
  end
end
