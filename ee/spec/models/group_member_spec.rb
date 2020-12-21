# frozen_string_literal: true
require 'spec_helper'

RSpec.describe GroupMember do
  it { is_expected.to include_module(EE::GroupMember) }

  it_behaves_like 'member validations'

  describe 'validations' do
    describe 'group domain limitations' do
      let(:group) { create(:group) }
      let(:gitlab_user) { create(:user, email: 'test@gitlab.com') }
      let(:gmail_user) { create(:user, email: 'test@gmail.com') }
      let(:unconfirmed_gitlab_user) { create(:user, :unconfirmed, email: 'unverified@gitlab.com') }
      let(:acme_user) { create(:user, email: 'user@acme.com') }

      before do
        create(:allowed_email_domain, group: group, domain: 'gitlab.com')
        create(:allowed_email_domain, group: group, domain: 'acme.com')
      end

      context 'when group has email domain feature switched on' do
        before do
          stub_licensed_features(group_allowed_email_domains: true)
        end

        it 'users email must match at least one of the allowed domain emails' do
          expect(build(:group_member, group: group, user: gmail_user)).to be_invalid
          expect(build(:group_member, group: group, user: gitlab_user)).to be_valid
          expect(build(:group_member, group: group, user: acme_user)).to be_valid
        end

        it 'invited email must match at least one of the allowed domain emails' do
          expect(build(:group_member, group: group, user: nil, invite_email: 'user@gmail.com')).to be_invalid
          expect(build(:group_member, group: group, user: nil, invite_email: 'user@gitlab.com')).to be_valid
          expect(build(:group_member, group: group, user: nil, invite_email: 'invite@acme.com')).to be_valid
        end

        it 'user emails matching allowed domain must be verified' do
          group_member = build(:group_member, group: group, user: unconfirmed_gitlab_user)

          expect(group_member).to be_invalid
          expect(group_member.errors[:user]).to include("email 'unverified@gitlab.com' is not a verified email.")
        end

        context 'with project bot users' do
          let_it_be(:project_bot) { create(:user, :project_bot, email: "bot@example.com") }

          it 'bot user email does not match' do
            expect(group.allowed_email_domains.include?(project_bot.email)).to be_falsey
          end

          it 'allows the project bot user' do
            expect(build(:group_member, group: group, user: project_bot)).to be_valid
          end
        end

        context 'with group SAML users' do
          let(:saml_provider) { create(:saml_provider, group: group) }

          let!(:group_related_identity) do
            create(:group_saml_identity, user: unconfirmed_gitlab_user, saml_provider: saml_provider)
          end

          it 'user emails does not have to be verified' do
            expect(build(:group_member, group: group, user: unconfirmed_gitlab_user)).to be_valid
          end
        end

        context 'with group SCIM users' do
          let!(:scim_identity) do
            create(:scim_identity, user: unconfirmed_gitlab_user, group: group)
          end

          it 'user emails does not have to be verified' do
            expect(build(:group_member, group: group, user: unconfirmed_gitlab_user)).to be_valid
          end
        end

        context 'when group is subgroup' do
          let(:subgroup) { create(:group, parent: group) }

          it 'users email must match at least one of the allowed domain emails' do
            expect(build(:group_member, group: subgroup, user: gmail_user)).to be_invalid
            expect(build(:group_member, group: subgroup, user: gitlab_user)).to be_valid
            expect(build(:group_member, group: subgroup, user: acme_user)).to be_valid
          end

          it 'invited email must match at least one of the allowed domain emails' do
            expect(build(:group_member, group: subgroup, user: nil, invite_email: 'user@gmail.com')).to be_invalid
            expect(build(:group_member, group: subgroup, user: nil, invite_email: 'user@gitlab.com')).to be_valid
            expect(build(:group_member, group: subgroup, user: nil, invite_email: 'invite@acme.com')).to be_valid
          end

          it 'user emails matching allowed domain must be verified' do
            group_member = build(:group_member, group: subgroup, user: unconfirmed_gitlab_user)

            expect(group_member).to be_invalid
            expect(group_member.errors[:user]).to include("email 'unverified@gitlab.com' is not a verified email.")
          end
        end
      end

      context 'when group has email domain feature switched off' do
        it 'users email need not match allowed domain emails' do
          expect(build(:group_member, group: group, user: gmail_user)).to be_valid
          expect(build(:group_member, group: group, user: gitlab_user)).to be_valid
          expect(build(:group_member, group: group, user: acme_user)).to be_valid
        end

        it 'invited email need not match allowed domain emails' do
          expect(build(:group_member, group: group, invite_email: 'user@gmail.com')).to be_valid
          expect(build(:group_member, group: group, invite_email: 'user@gitlab.com')).to be_valid
          expect(build(:group_member, group: group, invite_email: 'user@acme.com')).to be_valid
        end

        it 'user emails does not have to be verified' do
          expect(build(:group_member, group: group, user: unconfirmed_gitlab_user)).to be_valid
        end
      end
    end

    describe 'access level inclusion' do
      let(:group) { create(:group) }

      context 'when minimal access user feature switched on' do
        before do
          stub_licensed_features(minimal_access_role: true)
        end

        it 'users can have access levels from minimal access to owner' do
          expect(build(:group_member, group: group, user: create(:user), access_level: ::Gitlab::Access::NO_ACCESS)).to be_invalid
          expect(build(:group_member, group: group, user: create(:user), access_level: ::Gitlab::Access::MINIMAL_ACCESS)).to be_valid
          expect(build(:group_member, group: group, user: create(:user), access_level: ::Gitlab::Access::GUEST)).to be_valid
          expect(build(:group_member, group: group, user: create(:user), access_level: ::Gitlab::Access::REPORTER)).to be_valid
          expect(build(:group_member, group: group, user: create(:user), access_level: ::Gitlab::Access::DEVELOPER)).to be_valid
          expect(build(:group_member, group: group, user: create(:user), access_level: ::Gitlab::Access::MAINTAINER)).to be_valid
          expect(build(:group_member, group: group, user: create(:user), access_level: ::Gitlab::Access::OWNER)).to be_valid
        end

        context 'when group is a subgroup' do
          let(:subgroup) { create(:group, parent: group) }

          it 'users cannot have minimal access level' do
            expect(build(:group_member, group: subgroup, user: create(:user), access_level: ::Gitlab::Access::MINIMAL_ACCESS)).to be_invalid
          end
        end
      end

      context 'when minimal access user feature switched off' do
        before do
          stub_licensed_features(minimal_access_role: false)
        end

        it 'users can have access levels from guest to owner' do
          expect(build(:group_member, group: group, user: create(:user), access_level: ::Gitlab::Access::NO_ACCESS)).to be_invalid
          expect(build(:group_member, group: group, user: create(:user), access_level: ::Gitlab::Access::MINIMAL_ACCESS)).to be_invalid
          expect(build(:group_member, group: group, user: create(:user), access_level: ::Gitlab::Access::GUEST)).to be_valid
          expect(build(:group_member, group: group, user: create(:user), access_level: ::Gitlab::Access::REPORTER)).to be_valid
          expect(build(:group_member, group: group, user: create(:user), access_level: ::Gitlab::Access::DEVELOPER)).to be_valid
          expect(build(:group_member, group: group, user: create(:user), access_level: ::Gitlab::Access::MAINTAINER)).to be_valid
          expect(build(:group_member, group: group, user: create(:user), access_level: ::Gitlab::Access::OWNER)).to be_valid
        end
      end
    end
  end

  describe 'scopes' do
    describe '.by_group_ids' do
      it 'returns only members from selected groups' do
        group = create(:group)
        member1 = create(:group_member, group: group)
        member2 = create(:group_member, group: group)
        create(:group_member)

        expect(described_class.by_group_ids([group.id])).to match_array([member1, member2])
      end
    end

    describe '.with_saml_identity' do
      let(:saml_provider) { create :saml_provider }
      let(:group) { saml_provider.group }
      let!(:member) do
        create(:group_member, group: group).tap do |m|
          create(:group_saml_identity, saml_provider: saml_provider, user: m.user)
        end
      end

      let!(:member_without_identity) do
        create(:group_member, group: group)
      end

      let!(:member_with_different_identity) do
        create(:group_member, group: group).tap do |m|
          create(:group_saml_identity, user: m.user)
        end
      end

      it 'returns members with identity linked to given saml provider' do
        expect(described_class.with_saml_identity(saml_provider)).to eq([member])
      end
    end
  end

  describe '#group_saml_identity' do
    subject(:group_saml_identity) { member.group_saml_identity }

    let!(:member) { create :group_member }

    context 'without saml_provider' do
      it { is_expected.to eq nil }
    end

    context 'with saml_provider enabled' do
      let!(:saml_provider) { create(:saml_provider, group: member.group) }

      context 'when member has no connected identity' do
        it { is_expected.to eq nil }
      end

      context 'when member has connected identity' do
        let!(:group_related_identity) do
          create(:group_saml_identity, user: member.user, saml_provider: saml_provider)
        end

        it 'returns related identity' do
          expect(group_saml_identity).to eq group_related_identity
        end
      end

      context 'when member has connected identity of different group' do
        before do
          create(:group_saml_identity, user: member.user)
        end

        it { is_expected.to eq nil }
      end
    end
  end

  context 'group member webhooks', :sidekiq_inline do
    let_it_be(:group) { create(:group_with_plan, plan: :gold_plan) }
    let_it_be(:group_hook) { create(:group_hook, group: group, member_events: true) }
    let_it_be(:user) { create(:user) }

    context 'when a member is added to the group' do
      let(:group_member) { create(:group_member, group: group) }

      before do
        WebMock.stub_request(:post, group_hook.url)
      end

      it 'executes user_add_to_group event webhook' do
        group.add_guest(group_member.user)

        expect(WebMock).to have_requested(:post, group_hook.url).with(
          webhook_data(group_member, 'user_add_to_group')
        )
      end

      context 'ancestor groups' do
        let_it_be(:subgroup) { create(:group, parent: group) }
        let_it_be(:subgroup_hook) { create(:group_hook, group: subgroup, member_events: true) }

        it 'fires two webhooks when parent group has member_events webhook enabled' do
          WebMock.stub_request(:post, subgroup_hook.url)

          subgroup.add_guest(user)

          expect(WebMock).to have_requested(:post, subgroup_hook.url)
          expect(WebMock).to have_requested(:post, group_hook.url)
        end

        it 'fires one webhook when parent group has member_events webhook disabled' do
          group_hook = create(:group_hook, group: group, member_events: false)

          WebMock.stub_request(:post, subgroup_hook.url)

          subgroup.add_guest(user)

          expect(WebMock).to have_requested(:post, subgroup_hook.url)
          expect(WebMock).not_to have_requested(:post, group_hook.url)
        end
      end
    end

    context 'when a group member is updated' do
      let(:group_member) { create(:group_member, :developer, group: group, expires_at: 1.day.from_now) }

      it 'executes user_update_for_group event webhook when user role is updated' do
        WebMock.stub_request(:post, group_hook.url)

        group_member.update!(access_level: Gitlab::Access::MAINTAINER)

        expect(WebMock).to have_requested(:post, group_hook.url).with(
          webhook_data(group_member, 'user_update_for_group')
        )
      end

      it 'executes user_update_for_group event webhook when user expiration date is updated' do
        WebMock.stub_request(:post, group_hook.url)

        group_member.update!(expires_at: 2.days.from_now)

        expect(WebMock).to have_requested(:post, group_hook.url).with(
          webhook_data(group_member, 'user_update_for_group')
        )
      end
    end

    context 'when the group member is deleted' do
      let_it_be(:group_member) { create(:group_member, :developer, group: group, expires_at: 1.day.from_now) }

      it 'executes user_remove_from_group event webhook when group member is deleted' do
        WebMock.stub_request(:post, group_hook.url)

        group_member.destroy!

        expect(WebMock).to have_requested(:post, group_hook.url).with(
          webhook_data(group_member, 'user_remove_from_group')
        )
      end
    end

    context 'does not execute webhook' do
      before do
        WebMock.stub_request(:post, group_hook.url)
      end

      it 'does not execute webhooks if group member events webhook is disabled' do
        group_hook = create(:group_hook, group: group, member_events: false)

        group.add_guest(user)

        expect(WebMock).not_to have_requested(:post, group_hook.url)
      end

      it 'does not execute webhooks if feature flag is disabled' do
        stub_feature_flags(group_webhooks: false)

        group.add_guest(user)

        expect(WebMock).not_to have_requested(:post, group_hook.url)
      end
    end
  end

  def webhook_data(group_member, event)
    {
      headers: { 'Content-Type' => 'application/json', 'User-Agent' => "GitLab/#{Gitlab::VERSION}", 'X-Gitlab-Event' => 'Member Hook' },
      body: {
        created_at: group_member.created_at&.xmlschema,
        updated_at: group_member.updated_at&.xmlschema,
        group_name: group.name,
        group_path: group.path,
        group_id: group.id,
        user_username: group_member.user.username,
        user_name: group_member.user.name,
        user_email: group_member.user.email,
        user_id: group_member.user.id,
        group_access: group_member.human_access,
        expires_at: group_member.expires_at&.xmlschema,
        group_plan: 'gold',
        event_name: event
      }.to_json
    }
  end
end
