# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects members', :js do
  let(:user) { create(:user) }
  let(:developer) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:project) { create(:project, :public, creator: user, group: group) }
  let(:project_invitee) { create(:project_member, project: project, invite_token: '123', invite_email: 'test1@abc.com', user: nil) }
  let(:group_invitee) { create(:group_member, group: group, invite_token: '123', invite_email: 'test2@abc.com', user: nil) }
  let(:project_requester) { create(:user) }
  let(:group_requester) { create(:user) }

  before do
    project.add_developer(developer)
    group.add_owner(user)
    sign_in(user)
  end

  context 'with a group invitee' do
    before do
      group_invitee
      visit project_project_members_path(project)
    end

    it 'does not appear in the project members page' do
      page.within first('.content-list') do
        expect(page).not_to have_content('test2@abc.com')
      end
    end
  end

  context 'with a group' do
    it 'shows group and project members by default' do
      visit project_project_members_path(project)

      page.within first('.content-list') do
        expect(page).to have_content(developer.name)

        expect(page).to have_content(user.name)
        expect(page).to have_content(group.name)
      end
    end

    it 'shows project members only if requested' do
      visit project_project_members_path(project, with_inherited_permissions: 'exclude')

      page.within first('.content-list') do
        expect(page).to have_content(developer.name)

        expect(page).not_to have_content(user.name)
        expect(page).not_to have_content(group.name)
      end
    end

    it 'shows group members only if requested' do
      visit project_project_members_path(project, with_inherited_permissions: 'only')

      page.within first('.content-list') do
        expect(page).not_to have_content(developer.name)

        expect(page).to have_content(user.name)
        expect(page).to have_content(group.name)
      end
    end
  end

  context 'with a group, a project invitee, and a project requester' do
    before do
      group.request_access(group_requester)
      project.request_access(project_requester)
      group_invitee
      project_invitee
      visit project_project_members_path(project)
    end

    it 'shows the group owner' do
      page.within first('.content-list') do
        # Group owner
        expect(page).to have_content(user.name)
        expect(page).to have_content(group.name)
      end
    end

    it 'shows the project developer' do
      page.within first('.content-list') do
        # Project developer
        expect(page).to have_content(developer.name)
      end
    end

    it 'shows the project invitee' do
      click_link 'Invited'

      page.within first('.content-list') do
        expect(page).to have_content('test1@abc.com')
        expect(page).not_to have_content('test2@abc.com')
      end
    end

    it 'shows the project requester' do
      click_link 'Access requests'

      page.within first('.content-list') do
        expect(page).to have_content(project_requester.name)
        expect(page).not_to have_content(group_requester.name)
      end
    end
  end

  context 'with a group requester' do
    before do
      group.request_access(group_requester)
      visit project_project_members_path(project)
    end

    it 'does not appear in the project members page' do
      expect(page).not_to have_link('Access requests')
      page.within first('.content-list') do
        expect(page).not_to have_content(group_requester.name)
      end
    end
  end

  describe 'showing status of members' do
    it_behaves_like 'showing user status' do
      let(:user_with_status) { developer }

      subject { visit project_project_members_path(project) }
    end
  end
end
