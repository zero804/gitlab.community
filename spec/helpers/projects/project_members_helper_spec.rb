# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ProjectMembersHelper do
  describe '#can_manage_project_members?' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:project) { create(:project) }

    before do
      allow(helper).to receive(:current_user).and_return(current_user)
    end

    context 'when `current_user` has `admin_project_member` permissions' do
      before do
        allow(helper).to receive(:can?).with(current_user, :admin_project_member, project).and_return(true)
      end

      it 'returns `true`' do
        expect(helper.can_manage_project_members?(project)).to be(true)
      end
    end

    context 'when `current_user` does not have `admin_project_member` permissions' do
      before do
        allow(helper).to receive(:can?).with(current_user, :admin_project_member, project).and_return(false)
      end

      it 'returns `false`' do
        expect(helper.can_manage_project_members?(project)).to be(false)
      end
    end
  end
end
