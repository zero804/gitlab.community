# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Terraform::StatesFinder do
  describe '#execute' do
    let_it_be(:project) { create(:project) }

    let_it_be(:production_state) { create(:terraform_state, project: project) }
    let_it_be(:staging_state) { create(:terraform_state, project: project) }
    let_it_be(:other_state) { create(:terraform_state) }

    let(:user) { create(:user, developer_projects: [project]) }

    subject { described_class.new(project, user).execute }

    it 'returns states associated with the agent' do
      expect(subject).to contain_exactly(production_state, staging_state)
    end

    context 'user does not have permission' do
      let(:user) { create(:user) }

      it { is_expected.to be_empty }
    end
  end
end
