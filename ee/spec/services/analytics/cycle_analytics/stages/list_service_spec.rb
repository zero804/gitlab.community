# frozen_string_literal: true

require 'spec_helper'

describe Analytics::CycleAnalytics::Stages::ListService do
  let_it_be(:group, refind: true) { create(:group) }
  let_it_be(:user) { create(:user) }
  let(:stages) { subject.payload[:stages] }

  subject { described_class.new(parent: group, current_user: user).execute }

  before_all do
    group.add_reporter(user)
  end

  before do
    stub_licensed_features(cycle_analytics_for_groups: true)
  end

  it_behaves_like 'permission check for cycle analytics stage services', :cycle_analytics_for_groups

  it 'returns only the default stages' do
    expect(stages.size).to eq(Gitlab::Analytics::CycleAnalytics::DefaultStages.all.size)
  end

  it 'provides the default stages as non-persisted objects' do
    expect(stages.map(&:id)).to all(be_nil)
  end

  context 'when there are persisted stages' do
    let_it_be(:stage1) { create(:cycle_analytics_group_stage, parent: group, relative_position: 2) }
    let_it_be(:stage2) { create(:cycle_analytics_group_stage, parent: group, relative_position: 3) }
    let_it_be(:stage3) { create(:cycle_analytics_group_stage, parent: group, relative_position: 1) }

    it 'returns the persisted stages in order' do
      expect(stages).to eq([stage3, stage1, stage2])
    end
  end
end
