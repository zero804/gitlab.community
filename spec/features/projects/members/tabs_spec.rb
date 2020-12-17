# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Members > Tabs' do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, creator: user, namespace: user.namespace) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project_members) { create_list(:project_member, 2, project: project) }
  let_it_be(:access_requests) { create_list(:project_member, 2, :access_request, project: project) }
  let_it_be(:invites) { create_list(:project_member, 2, :invited, project: project) }
  let_it_be(:project_group_links) { create_list(:project_group_link, 2, project: project) }

  shared_examples 'active "Members" tab' do
    it 'displays "Members" tab' do
      expect(page).to have_selector('.nav-link.active', text: 'Members')
    end
  end

  before do
    allow(Kaminari.config).to receive(:default_per_page).and_return(1)

    sign_in(user)
    visit project_project_members_path(project)
  end

  where(:tab, :count) do
    'Members'         | 3
    'Invited'         | 2
    'Groups'          | 2
    'Access requests' | 2
  end

  with_them do
    it "renders #{params[:tab]} tab" do
      expect(page).to have_selector('.nav-link', text: "#{tab} #{count}")
    end
  end

  context 'displays "Members" tab by default' do
    it_behaves_like 'active "Members" tab'
  end

  context 'when searching "Groups"', :js do
    before do
      click_link 'Groups'

      page.within '[data-testid="group-link-search-form"]' do
        fill_in 'search_groups', with: 'group'
        find('button[type="submit"]').click
      end
    end

    it 'displays "Groups" tab' do
      expect(page).to have_selector('.nav-link.active', text: 'Groups')
    end

    context 'and then searching "Members"' do
      before do
        click_link 'Members 3'

        page.within '[data-testid="user-search-form"]' do
          fill_in 'search', with: 'user'
          find('button[type="submit"]').click
        end
      end

      it_behaves_like 'active "Members" tab'
    end
  end
end
