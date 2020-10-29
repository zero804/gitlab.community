# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Terraform::StatesResolver do
  include GraphqlHelpers

  it { expect(described_class.type).to eq(Types::Terraform::StateType) }
  it { expect(described_class.null).to be_truthy }

  describe '#resolve' do
    let_it_be(:project) { create(:project) }

    let(:finder) { double(execute: relation) }
    let(:relation) { double }
    let(:ctx) { Hash(current_user: user) }
    let(:user) { create(:user, developer_projects: [project]) }

    subject { resolve(described_class, obj: project, ctx: ctx) }

    it 'calls the states finder' do
      expect(Terraform::StatesFinder).to receive(:new)
        .with(project, user).and_return(finder)

      expect(subject).to eq(relation)
    end
  end
end
