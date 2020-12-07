# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Todos::Destroy::EntityLeaveService do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }

  let_it_be(:epic1) { create(:epic, confidential: true, group: subgroup) }
  let_it_be(:epic2) { create(:epic, group: subgroup) }
  let!(:todo1) { create(:todo, target: epic1, user: user, group: subgroup) }
  let!(:todo2) { create(:todo, target: epic2, user: user, group: subgroup) }

  describe '#execute' do
    subject { described_class.new(user.id, subgroup.id, 'Group').execute }

    shared_examples 'removes only confidential epics todos' do
      it 'removes todos targeting confidential epics in the group' do
        expect { subject }.to change { Todo.count }.by(-1)
        expect(user.reload.todos.ids).to match_array(todo2.id)
      end
    end

    it_behaves_like 'removes only confidential epics todos'

    context 'when user is still member of ancestor group' do
      before do
        group.add_reporter(user)
      end

      it 'does not remove todos targeting confidential epics in the group' do
        expect { subject }.not_to change { Todo.count }
      end
    end

    context 'when user role is downgraded to guest' do
      before do
        subgroup.add_guest(user)
      end

      it_behaves_like 'removes only confidential epics todos'
    end
  end
end
