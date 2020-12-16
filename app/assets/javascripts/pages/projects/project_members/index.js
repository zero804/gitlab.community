import Vue from 'vue';
import Members from 'ee_else_ce/members';
import memberExpirationDate from '~/member_expiration_date';
import UsersSelect from '~/users_select';
import groupsSelect from '~/groups_select';
import RemoveMemberModal from '~/vue_shared/components/remove_member_modal.vue';
import initInviteMembersTrigger from '~/invite_members/init_invite_members_trigger';
import initInviteGroupTrigger from '~/invite_members/init_invite_group_trigger';
import createStore from '~/invite_members/store';
import initInviteMembersModal from '~/invite_members/init_invite_members_modal';

function mountRemoveMemberModal() {
  const el = document.querySelector('.js-remove-member-modal');
  if (!el) {
    return false;
  }

  return new Vue({
    el,
    render(createComponent) {
      return createComponent(RemoveMemberModal);
    },
  });
}

document.addEventListener('DOMContentLoaded', () => {
  groupsSelect();
  memberExpirationDate();
  memberExpirationDate('.js-access-expiration-date-groups');
  mountRemoveMemberModal();

  initInviteGroupTrigger();
  initInviteMembersTrigger();
  const groupStore = createStore();
  initInviteMembersModal(groupStore);

  new Members(); // eslint-disable-line no-new
  new UsersSelect(); // eslint-disable-line no-new
});
