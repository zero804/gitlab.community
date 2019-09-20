# frozen_string_literal: true
require 'spec_helper'

describe DesignManagement::Version do
  describe 'relations' do
    it { is_expected.to have_many(:actions) }
    it { is_expected.to have_many(:designs).through(:actions) }

    it 'constrains the designs relation correctly' do
      design = create(:design)
      version = create(:design_version, designs: [design])

      expect { version.designs << design }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'allows adding multiple versions to a single design' do
      design = create(:design)
      versions = create_list(:design_version, 2)

      expect { versions.each { |v| design.versions << v } }
        .not_to raise_error
    end
  end

  describe 'validations' do
    subject(:design_version) { build(:design_version) }

    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:author) }
    it { is_expected.to validate_presence_of(:sha) }
    it { is_expected.to validate_presence_of(:designs) }
    it { is_expected.to validate_presence_of(:issue_id) }
    it { is_expected.to validate_uniqueness_of(:sha).scoped_to(:issue_id).case_insensitive }
  end

  describe "scopes" do
    let(:version_1) { create(:design_version) }
    let(:version_2) { create(:design_version) }

    describe ".for_designs" do
      it "only returns versions related to the specified designs" do
        _other_version = create(:design_version)
        designs = [create(:design, versions: [version_1]),
                   create(:design, versions: [version_2])]

        expect(described_class.for_designs(designs))
          .to contain_exactly(version_1, version_2)
      end
    end

    describe '.earlier_or_equal_to' do
      it 'only returns versions created earlier or later than the given version' do
        expect(described_class.earlier_or_equal_to(version_1)).to eq([version_1])
        expect(described_class.earlier_or_equal_to(version_2)).to contain_exactly(version_1, version_2)
      end

      it 'can be passed either a DesignManagement::Design or an ID' do
        [version_1, version_1.id].each do |arg|
          expect(described_class.earlier_or_equal_to(arg)).to eq([version_1])
        end
      end
    end
  end

  describe ".create_for_designs" do
    def current_version_id(design)
      design.send(:head_version).try(:id)
    end

    def as_actions(designs, action = :create)
      designs.map do |d|
        DesignManagement::DesignAction.new(d, action, action == :delete ? nil : :content)
      end
    end

    set(:author) { create(:user) }
    set(:issue) { create(:issue) }
    set(:design_a) { create(:design, issue: issue) }
    set(:design_b) { create(:design, issue: issue) }
    let(:designs) { [design_a, design_b] }

    describe 'the error raised when there are no actions' do
      let(:sha) { 'f00' }

      def call_with_empty_actions
        described_class.create_for_designs([], sha, author)
      end

      it 'raises CouldNotCreateVersion' do
        expect { call_with_empty_actions }
          .to raise_error(described_class::CouldNotCreateVersion)
      end

      it 'has an appropriate cause' do
        expect { call_with_empty_actions }
          .to raise_error(have_attributes(cause: ActiveRecord::RecordInvalid))
      end

      it 'provides extra data sentry can consume' do
        extra_info = a_hash_including(sha: sha)

        expect { call_with_empty_actions }
          .to raise_error(have_attributes(sentry_extra_data: extra_info))
      end
    end

    describe 'the error raised when the designs come from different issues' do
      let(:sha) { 'f00' }
      let(:designs) { create_list(:design, 2) }
      let(:actions) { as_actions(designs) }

      def call_with_mismatched_designs
        described_class.create_for_designs(actions, sha, author)
      end

      it 'raises CouldNotCreateVersion' do
        expect { call_with_mismatched_designs }
          .to raise_error(described_class::CouldNotCreateVersion)
      end

      it 'has an appropriate cause' do
        expect { call_with_mismatched_designs }
          .to raise_error(have_attributes(cause: described_class::NotSameIssue))
      end

      it 'provides extra data sentry can consume' do
        extra_info = a_hash_including(design_ids: designs.map(&:id))

        expect { call_with_mismatched_designs }
          .to raise_error(have_attributes(sentry_extra_data: extra_info))
      end
    end

    it 'does not leave invalid versions around if creation fails' do
      expect do
        described_class.create_for_designs([], 'abcdef', author) rescue nil
      end.not_to change { described_class.count }
    end

    it 'does not leave orphaned design-versions around if creation fails' do
      actions = as_actions(designs)
      expect do
        described_class.create_for_designs(actions, '', author) rescue nil
      end.not_to change { DesignManagement::Action.count }
    end

    it 'creates a version and links it to multiple designs' do
      actions = as_actions(designs, :create)

      version = described_class.create_for_designs(actions, 'abc', author)

      expect(version.designs).to contain_exactly(*designs)
      expect(designs.map(&method(:current_version_id))).to all(eq version.id)
    end

    it 'creates designs if they are new to git' do
      actions = as_actions(designs, :create)

      described_class.create_for_designs(actions, 'abc', author)

      expect(designs.map(&:most_recent_action)).to all(be_creation)
    end

    it 'correctly associates the version with the issue' do
      actions = as_actions(designs)

      version = described_class.create_for_designs(actions, 'abc', author)

      expect(version.issue).to eq(issue)
    end

    it 'correctly associates the version with the author' do
      actions = as_actions(designs)

      version = described_class.create_for_designs(actions, 'abc', author)

      expect(version.author).to eq(author)
    end

    it 'modifies designs if git updated them' do
      actions = as_actions(designs, :update)

      described_class.create_for_designs(actions, 'abc', author)

      expect(designs.map(&:most_recent_action)).to all(be_modification)
    end

    it 'deletes designs when the git action was delete' do
      actions = as_actions(designs, :delete)

      described_class.create_for_designs(actions, 'def', author)

      expect(designs).to all(be_deleted)
    end

    it 're-creates designs if they are deleted' do
      described_class.create_for_designs(as_actions(designs, :create), 'abc', author)
      described_class.create_for_designs(as_actions(designs, :delete), 'def', author)

      expect(designs).to all(be_deleted)

      described_class.create_for_designs(as_actions(designs, :create), 'ghi', author)

      expect(designs.map(&:most_recent_action)).to all(be_creation)
      expect(designs).not_to include(be_deleted)
    end

    it 'changes the version of the designs' do
      actions = as_actions([design_a])
      described_class.create_for_designs(actions, 'before', author)

      expect do
        described_class.create_for_designs(actions, 'after', author)
      end.to change { current_version_id(design_a) }
    end
  end

  describe '#designs_by_event' do
    context 'there is a single design' do
      set(:design) { create(:design) }

      shared_examples :a_correctly_categorised_design do |kind, category|
        let(:version) { create(:design_version, kind => [design]) }

        it 'returns a hash with a single key and the single design in that bucket' do
          expect(version.designs_by_event).to eq(category => [design])
        end
      end

      it_behaves_like :a_correctly_categorised_design, :created_designs, 'creation'
      it_behaves_like :a_correctly_categorised_design, :modified_designs, 'modification'
      it_behaves_like :a_correctly_categorised_design, :deleted_designs, 'deletion'
    end

    context 'there are a bunch of different designs in a variety of states' do
      let(:version) do
        create(:design_version,
               created_designs: create_list(:design, 3),
               modified_designs: create_list(:design, 4),
               deleted_designs: create_list(:design, 5))
      end

      it 'puts them in the right buckets' do
        expect(version.designs_by_event).to match(
          a_hash_including(
            'creation' =>  have_attributes(size: 3),
            'modification' => have_attributes(size: 4),
            'deletion' => have_attributes(size: 5)
          )
        )
      end

      it 'does not suffer from N+1 queries' do
        version.designs.map(&:id) # we don't care about the set-up queries
        expect { version.designs_by_event }.not_to exceed_query_limit(2)
      end
    end
  end

  describe '#author' do
    it 'returns the author' do
      author = build(:user)
      version = build(:design_version, author: author)

      expect(version.author).to eq(author)
    end

    it 'returns nil if author_id is nil and version is not persisted' do
      version = build(:design_version, author: nil)

      expect(version.author_id).to eq(nil)
      expect(version.author).to eq(nil)
    end

    it 'returns the ghost user if author_id is nil and version has been persisted' do
      author = create(:user)
      version = create(:design_version, author: author)
      author.destroy
      version.reload

      expect(version.author_id).to eq(nil)
      expect(version.author).to eq(User.ghost)
    end
  end

  describe '#lazy_author' do
    it 'batch loads all user records' do
      versions = create_list(:design_version, 5)

      expect { versions.map(&:lazy_author).map(&:id) }.not_to exceed_query_limit(1)
    end

    it 'returns the author' do
      version = create(:design_version)

      expect(version.lazy_author).to eq(version.author)
    end

    it 'returns nil if author_id is nil and version is not persisted' do
      version = build(:design_version, author: nil)

      expect(version.author_id).to eq(nil)
      expect(version.lazy_author).to eq(nil)
    end

    it 'returns the ghost user if author is deleted and version has been persisted' do
      author = create(:user)
      version = create(:design_version, author: author)
      author.destroy
      version.reload

      expect(version.lazy_author).to eq(User.ghost)
    end
  end
end
