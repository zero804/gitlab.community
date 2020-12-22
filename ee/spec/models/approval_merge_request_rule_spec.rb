# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApprovalMergeRequestRule do
  let(:merge_request) { create(:merge_request) }

  subject(:amrr) do
    create(:approval_merge_request_rule,
      merge_request: merge_request
    )
  end

  describe 'associations' do
    subject { build_stubbed(:approval_merge_request_rule) }

    it { is_expected.to have_one(:approval_project_rule_project).through(:approval_project_rule) }
  end

  describe 'validations' do
    it 'is valid' do
      expect(build(:approval_merge_request_rule)).to be_valid
    end

    it 'is invalid when the name is missing' do
      expect(build(:approval_merge_request_rule, name: nil)).not_to be_valid
    end

    it 'is invalid when name not unique within rule type and merge request' do
      is_expected.to validate_uniqueness_of(:name).scoped_to([:merge_request_id, :rule_type, :section])
    end

    context 'approval_project_rule is set' do
      let(:approval_project_rule) { build(:approval_project_rule) }
      let(:merge_request_rule) { build(:approval_merge_request_rule, merge_request: merge_request, approval_project_rule: approval_project_rule) }

      context 'when project of approval_project_rule and merge request matches' do
        let(:merge_request) { build(:merge_request, project: approval_project_rule.project) }

        it 'is valid' do
          expect(merge_request_rule).to be_valid
        end
      end

      context 'when the project of approval_project_rule and merge request does not match' do
        it 'is invalid' do
          expect(merge_request_rule).to be_invalid
        end
      end
    end

    context 'code owner rules' do
      it 'is valid' do
        expect(build(:code_owner_rule)).to be_valid
      end

      it 'is invalid when reusing the same name within the same merge request' do
        existing = create(:code_owner_rule, name: '*.rb', merge_request: merge_request, section: 'section')

        new = build(:code_owner_rule, merge_request: existing.merge_request, name: '*.rb', section: 'section')

        expect(new).not_to be_valid
        expect { new.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
      end

      it 'allows a regular rule with the same name as the codeowner rule' do
        create(:code_owner_rule, name: '*.rb', merge_request: merge_request)

        new = build(:approval_merge_request_rule, name: '*.rb', merge_request: merge_request)

        expect(new).to be_valid
        expect { new.save! }.not_to raise_error
      end
    end

    context 'report_approver rules' do
      it 'is valid' do
        expect(build(:report_approver_rule)).to be_valid
      end

      it 'validates presence of report_type' do
        rule = build(:report_approver_rule)
        expect(rule).to be_valid

        rule.report_type = nil
        expect(rule).not_to be_valid
      end
    end

    context 'any_approver rules' do
      let(:rule) { build(:approval_merge_request_rule, merge_request: merge_request, rule_type: :any_approver) }

      it 'creating only one any_approver rule is allowed' do
        create(:approval_merge_request_rule, merge_request: merge_request, rule_type: :any_approver)

        expect(rule).not_to be_valid
        expect(rule.errors.messages).to eq(rule_type: ['any-approver for the merge request already exists'])
        expect { rule.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end
  end

  describe '.regular_or_any_approver scope' do
    it 'returns regular or any-approver rules' do
      any_approver_rule = create(:any_approver_rule)
      regular_rule = create(:approval_merge_request_rule)
      create(:report_approver_rule)

      expect(described_class.regular_or_any_approver).to(
        contain_exactly(any_approver_rule, regular_rule)
      )
    end
  end

  shared_examples_for 'attempts to read the value from the AMRR record itself' do
    it 'as expected' do
      expect(amrr)
        .to receive(:retrieve_value_from_record)
        .at_least(:once)
        .and_call_original

      amrr.send(method_name)
    end
  end

  describe 'custom getters' do
    let(:approval_project_rule) do
      create(:approval_project_rule, project: merge_request.project)
    end

    let(:amrr) do
      create(:approval_merge_request_rule,
        merge_request: merge_request,
        approval_project_rule: approval_project_rule
      )
    end

    %i(name approvals_required users groups).each do |method_name|
      let(:method_name) { method_name }

      context 'when source_rule is present' do
        context 'the AMRR rule has been modified' do
          before do
            amrr.modified_from_project_rule = true
          end

          it_behaves_like 'attempts to read the value from the AMRR record itself'
        end

        context 'the AMRR rule has not been modified' do
          before do
            amrr.modified_from_project_rule = false
          end

          it 'attempts to read the value from the source rule (ApprovalProjectRule)' do
            expect(amrr.approval_project_rule)
              .to receive(method_name)
              .at_least(:once)
              .and_call_original

            amrr.send(method_name)
          end
        end
      end

      context 'when source_rule is missing' do
        before do
          allow(amrr).to receive(:source_rule).and_return(nil)
        end

        it_behaves_like 'attempts to read the value from the AMRR record itself'
      end
    end
  end

  context 'scopes' do
    let!(:rb_rule) { create(:code_owner_rule, name: '*.rb') }
    let!(:js_rule) { create(:code_owner_rule, name: '*.js') }
    let!(:css_rule) { create(:code_owner_rule, name: '*.css') }
    let!(:approval_rule) { create(:approval_merge_request_rule) }
    let!(:report_approver_rule) { create(:report_approver_rule) }

    describe '.not_matching_pattern' do
      it 'returns the correct rules' do
        expect(described_class.not_matching_pattern(['*.rb', '*.js']))
          .to contain_exactly(css_rule)
      end
    end

    describe '.matching_pattern' do
      it 'returns the correct rules' do
        expect(described_class.matching_pattern(['*.rb', '*.js']))
          .to contain_exactly(rb_rule, js_rule)
      end
    end

    describe '.code_owners' do
      it 'returns the correct rules' do
        expect(described_class.code_owner)
          .to contain_exactly(rb_rule, js_rule, css_rule)
      end
    end

    describe '.vulnerability_report' do
      it 'returns the correct rules' do
        expect(described_class.vulnerability_report)
          .to contain_exactly(report_approver_rule)
      end
    end
  end

  describe '.find_or_create_code_owner_rule' do
    subject(:rule) { described_class.find_or_create_code_owner_rule(merge_request, entry) }

    let(:entry) { Gitlab::CodeOwners::Entry.new("*.js", "@user") }

    context "when there is an existing rule" do
      let!(:existing_code_owner_rule) do
        create(:code_owner_rule, name: '*.rb', merge_request: merge_request)
      end

      let(:entry) { Gitlab::CodeOwners::Entry.new("*.rb", "@user") }

      it 'finds the existing rule' do
        expect(rule).to eq(existing_code_owner_rule)
      end

      context "when the existing rule matches name but not section" do
        let(:entry) { Gitlab::CodeOwners::Entry.new("*.rb", "@user", "example_section") }

        it "creates a new rule" do
          expect(rule).not_to eq(existing_code_owner_rule)
        end
      end
    end

    it 'creates a new rule if it does not exist' do
      expect { rule }
        .to change { merge_request.approval_rules.matching_pattern('*.js').count }.by(1)
    end

    it 'finds an existing rule using rule_type column' do
      regular_rule_type_rule = create(
        :code_owner_rule,
        name:          entry.pattern,
        merge_request: merge_request,
        rule_type:     described_class.rule_types[:regular]
      )

      expect(rule).not_to eq(regular_rule_type_rule)
    end

    it 'retries when a record was created between the find and the create' do
      expect(described_class).to receive(:code_owner).and_raise(ActiveRecord::RecordNotUnique)
      allow(described_class).to receive(:code_owner).and_call_original

      expect(rule).not_to be_nil
    end

    context "when section is present" do
      let(:entry) { Gitlab::CodeOwners::Entry.new("*.js", "@user", "Test Section") }

      it "creates a new rule and saves section when present" do
        expect(subject.section).to eq(entry.section)
      end
    end
  end

  describe '#project' do
    it 'returns project of MergeRequest' do
      expect(subject.project).to be_present
      expect(subject.project).to eq(merge_request.project)
    end
  end

  describe '#regular' do
    it 'returns true for regular records' do
      subject = create(:approval_merge_request_rule, merge_request: merge_request)

      expect(subject.regular).to eq(true)
      expect(subject.regular?).to eq(true)
    end

    it 'returns false for code owner records' do
      subject = create(:code_owner_rule, merge_request: merge_request)

      expect(subject.regular).to eq(false)
      expect(subject.regular?).to eq(false)
    end

    it 'returns false for any approver records' do
      subject = create(:approval_merge_request_rule, merge_request: merge_request, rule_type: :any_approver)

      expect(subject.regular).to eq(false)
      expect(subject.regular?).to eq(false)
    end
  end

  describe '#code_owner?' do
    let(:code_owner_rule) { build(:code_owner_rule) }

    context "rule_type is :code_owner" do
      it "returns true" do
        expect(code_owner_rule.code_owner?).to be true
      end
    end

    context "rule_type is :regular" do
      before do
        code_owner_rule.rule_type = :regular
      end

      it "returns false" do
        expect(code_owner_rule.code_owner?).to be false
      end
    end
  end

  describe '#approvers' do
    before do
      create(:group) do |group|
        group.add_guest(merge_request.author)
        subject.groups << group
      end
    end

    context 'when project merge_requests_author_approval is true' do
      it 'contains author' do
        merge_request.project.update(merge_requests_author_approval: true)

        expect(subject.approvers).to contain_exactly(merge_request.author)
      end
    end

    context 'when project merge_requests_author_approval is false' do
      before do
        merge_request.project.update(merge_requests_author_approval: false)
      end

      it 'does not contain author' do
        expect(subject.approvers).to be_empty
      end

      context 'when the rule\'s users have already been loaded' do
        before do
          subject.users
          subject.group_users
        end

        it 'does not contain the author' do
          expect(subject.approvers).to be_empty
        end
      end
    end
  end

  describe '#sync_approved_approvers' do
    let(:member1) { create(:user) }
    let(:member2) { create(:user) }
    let(:member3) { create(:user) }
    let!(:approval1) { create(:approval, merge_request: merge_request, user: member1) }
    let!(:approval2) { create(:approval, merge_request: merge_request, user: member2) }
    let!(:approval3) { create(:approval, merge_request: merge_request, user: member3) }

    let(:any_approver_rule) { create(:any_approver_rule, merge_request: merge_request) }

    before do
      subject.users = [member1, member2]
    end

    context 'when not merged' do
      it 'does nothing' do
        subject.sync_approved_approvers
        any_approver_rule.sync_approved_approvers

        expect(subject.approved_approvers.reload).to be_empty
        expect(any_approver_rule.approved_approvers).to be_empty
      end
    end

    context 'when merged' do
      let(:merge_request) { create(:merged_merge_request) }

      it 'records approved approvers as approved_approvers association' do
        subject.sync_approved_approvers

        expect(subject.approved_approvers.reload).to contain_exactly(member1, member2)
      end

      it 'stores all the approvals for any-approver rule' do
        any_approver_rule.sync_approved_approvers

        expect(any_approver_rule.approved_approvers.reload).to contain_exactly(member1, member2, member3)
      end
    end
  end

  describe 'validations' do
    describe 'approvals_required' do
      subject { build(:approval_merge_request_rule, merge_request: merge_request) }

      it 'is a natural number' do
        subject.assign_attributes(approvals_required: 2)
        expect(subject).to be_valid

        subject.assign_attributes(approvals_required: 0)
        expect(subject).to be_valid

        subject.assign_attributes(approvals_required: -1)
        expect(subject).to be_invalid
      end
    end
  end

  describe "#refresh_required_approvals!" do
    before do
      stub_licensed_features(license_scanning: true)
    end

    context "when the rule is a `#{ApprovalRuleLike::DEFAULT_NAME_FOR_LICENSE_REPORT}` rule" do
      subject { create(:report_approver_rule, :requires_approval, :license_scanning, merge_request: open_merge_request) }

      let(:open_merge_request) { create(:merge_request, :opened, target_project: project, source_project: project) }
      let!(:project_approval_rule) { create(:approval_project_rule, :requires_approval, :license_scanning, project: project) }
      let(:project) { create(:project) }
      let!(:open_pipeline) { create(:ee_ci_pipeline, :success, :with_license_scanning_report, project: project, merge_requests_as_head_pipeline: [open_merge_request]) }
      let!(:denied_policy) { create(:software_license_policy, project: project, software_license: license, classification: :denied) }

      before do
        subject.refresh_required_approvals!(project_approval_rule)
      end

      context "when the latest license report violates the compliance policy" do
        let(:license) { create(:software_license, name: license_report.license_names[0]) }
        let(:license_report) { open_pipeline.license_scanning_report }

        specify { expect(subject.approvals_required).to be(project_approval_rule.approvals_required) }
      end

      context "when the latest license report adheres to the compliance policy" do
        let(:license) { create(:software_license, name: SecureRandom.uuid) }

        specify { expect(subject.approvals_required).to be_zero }
      end
    end
  end
end
