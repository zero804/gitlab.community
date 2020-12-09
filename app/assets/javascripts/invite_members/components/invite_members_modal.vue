<script>
import {
  GlModal,
  GlDropdown,
  GlDropdownItem,
  GlDatepicker,
  GlLink,
  GlSprintf,
  GlButton,
  GlFormInput,
} from '@gitlab/ui';
import { partition, isString } from 'lodash';
import eventHub from '../event_hub';
import { s__, __, sprintf } from '~/locale';
import Api from '~/api';
import MembersTokenSelect from '~/invite_members/components/members_token_select.vue';
import GroupFilter from '~/invite_members/components/group_filter.vue';

export default {
  name: 'InviteMembersModal',
  components: {
    GlDatepicker,
    GlLink,
    GlModal,
    GlDropdown,
    GlDropdownItem,
    GlSprintf,
    GlButton,
    GlFormInput,
    MembersTokenSelect,
    GroupFilter,
  },
  props: {
    id: {
      type: String,
      required: true,
    },
    isProject: {
      type: Boolean,
      required: true,
    },
    name: {
      type: String,
      required: true,
    },
    accessLevels: {
      type: Object,
      required: true,
    },
    defaultAccessLevel: {
      type: String,
      required: true,
    },
    helpLink: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      visible: true,
      modalId: 'invite-members-modal',
      selectedAccessLevel: this.defaultAccessLevel,
      newUsersToInvite: [],
      isInviteGroup: false,
      selectedDate: undefined,
    };
  },
  computed: {
    inviteToName() {
      return this.name.toUpperCase();
    },
    inviteToType() {
      return this.isProject ? __('project') : __('group');
    },
    introText() {
      return sprintf(s__("InviteMembersModal|You're inviting %{invitee} to the %{name} %{type}"), {
        name: this.inviteToName,
        type: this.inviteToType,
        invitee: this.isInviteGroup ? __('a group') : __('members'),
      });
    },
    //isInviteGroup() {
    //  return this.isInviteGroup;
    //},
    modalTitle() {
      return this.isInviteGroup
        ? this.$options.labels.modalTitleGroup
        : this.$options.labels.modalTitleMembers;
    },
    searchFieldLabel() {
      return this.isInviteGroup
        ? this.$options.labels.groupToInvite
        : this.$options.labels.newUsersToInvite;
    },
    searchPlaceholder() {
      return this.isInviteGroup
        ? this.$options.labels.groupPlaceholder
        : this.$options.labels.userPlaceholder;
    },
    toastOptions() {
      return {
        onComplete: () => {
          this.selectedAccessLevel = this.defaultAccessLevel;
          this.newUsersToInvite = [];
        },
      };
    },
    basePostData() {
      return {
        access_level: this.selectedAccessLevel,
        expires_at: this.selectedDate,
        format: 'json',
      };
    },
    selectedRoleName() {
      return Object.keys(this.accessLevels).find(
        key => this.accessLevels[key] === Number(this.selectedAccessLevel),
      );
    },
  },
  mounted() {
    eventHub.$on('openModal', this.openModal);
    eventHub.$on('openInviteGroupModal', this.openInviteGroupModal);
  },
  methods: {
    partitionNewUsersToInvite() {
      const [usersToInviteByEmail, usersToInviteById] = partition(
        this.newUsersToInvite,
        user => isString(user.id) && user.id.includes('user-defined-token'),
      );

      return [
        usersToInviteByEmail.map(user => user.name).join(','),
        usersToInviteById.map(user => user.id).join(','),
      ];
    },
    openInviteGroupModal() {
      this.isInviteGroup = true;

      this.$root.$emit('bv::show::modal', this.modalId);
    },
    openModal() {
      this.isInviteGroup = false;

      this.$root.$emit('bv::show::modal', this.modalId);
    },
    closeModal() {
      this.$root.$emit('bv::hide::modal', this.modalId);
    },
    sendInvite() {
      this.submitForm();
      this.closeModal();
    },
    cancelInvite() {
      this.selectedAccessLevel = this.defaultAccessLevel;
      this.selectedDate = undefined;
      this.newUsersToInvite = '';
      this.closeModal();
    },
    changeSelectedItem(item) {
      this.selectedAccessLevel = item;
    },
    submitForm() {
      const [usersToInviteByEmail, usersToInviteById] = this.partitionNewUsersToInvite();
      const promises = [];

      if (usersToInviteByEmail !== '') {
        const apiInviteByEmail = this.isProject
          ? Api.inviteProjectMembersByEmail.bind(Api)
          : Api.inviteGroupMembersByEmail.bind(Api);

        promises.push(apiInviteByEmail(this.id, this.inviteByEmailPostData(usersToInviteByEmail)));
      }

      if (usersToInviteById !== '') {
        const apiAddById = this.isProject
          ? Api.inviteProjectMembers.bind(Api)
          : Api.inviteGroupMembers.bind(Api);

        promises.push(apiAddById(this.id, this.addByIdPostData(usersToInviteById)));
      }

      Promise.all(promises)
        .then(this.showToastMessageSuccess)
        .catch(this.showToastMessageError);
    },
    inviteByEmailPostData(usersToInviteByEmail) {
      if (usersToInviteByEmail === undefined) return this.basePostData;

      return { ...this.basePostData, email: usersToInviteByEmail };
    },
    addByIdPostData(usersToInviteById) {
      if (usersToInviteById === undefined) return this.basePostData;

      return { ...this.basePostData, user_id: usersToInviteById };
    },
    showToastMessageSuccess() {
      this.$toast.show(this.$options.labels.toastMessageSuccessful, this.toastOptions);
    },
    showToastMessageError(error) {
      const message = error.response.data.message || this.$options.labels.toastMessageUnsuccessful;

      this.$toast.show(message, this.toastOptions);
    },
  },
  labels: {
    modalTitleMembers: s__('InviteMembersModal|Invite team members'),
    modalTitleGroup: s__('InviteMembersModal|Invite a group'),
    newUsersToInvite: s__('InviteMembersModal|GitLab member or Email address'),
    groupToInvite: s__('InviteMembersModal|Select a group to invite'),
    userPlaceholder: s__('InviteMembersModal|Search for members to invite'),
    groupPlaceholder: s__('InviteMembersModal|Search for a group to invite'),
    accessLevel: s__('InviteMembersModal|Choose a role permission'),
    accessExpireDate: s__('InviteMembersModal|Access expiration date (optional)'),
    toastMessageSuccessful: s__('InviteMembersModal|Members were successfully added'),
    toastMessageUnsuccessful: s__('InviteMembersModal|Some of the members could not be added'),
    readMoreText: s__(`InviteMembersModal|%{linkStart}Read more%{linkEnd} about role permissions`),
    inviteButtonText: s__('InviteMembersModal|Invite'),
    cancelButtonText: s__('InviteMembersModal|Cancel'),
    headerCloseLabel: s__('InviteMembersModal|Close invite team members'),
  },
  membersTokenSelectLabelId: 'invite-members-input',
};
</script>
<template>
  <gl-modal
    :modal-id="modalId"
    size="sm"
    :title="modalTitle"
    :header-close-label="$options.labels.headerCloseLabel"
  >
    <div class="gl-ml-5 gl-mr-5">
      <div>{{ introText }}</div>

      <label :id="$options.membersTokenSelectLabelId" class="gl-font-weight-bold gl-mt-5">{{
        searchFieldLabel
      }}</label>
      <div class="gl-mt-2">
        <members-token-select
          v-if="!isInviteGroup"
          v-model="newUsersToInvite"
          :is-invite-group="isInviteGroup"
          :label="searchFieldLabel"
          :aria-labelledby="$options.membersTokenSelectLabelId"
          :placeholder="searchPlaceholder"
        />
        <group-filter v-if="isInviteGroup" />
      </div>

      <label class="gl-font-weight-bold gl-mt-5">{{ $options.labels.accessLevel }}</label>
      <div class="gl-mt-2 gl-w-half gl-xs-w-full">
        <gl-dropdown class="gl-shadow-none gl-w-full" v-bind="$attrs" :text="selectedRoleName">
          <template v-for="(key, item) in accessLevels">
            <gl-dropdown-item
              :key="key"
              active-class="is-active"
              :is-checked="key === selectedAccessLevel"
              @click="changeSelectedItem(key)"
            >
              <div>{{ item }}</div>
            </gl-dropdown-item>
          </template>
        </gl-dropdown>
      </div>

      <div class="gl-mt-2">
        <gl-sprintf :message="$options.labels.readMoreText">
          <template #link="{content}">
            <gl-link :href="helpLink" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </div>

      <label class="gl-font-weight-bold gl-mt-5" for="expires_at">{{
        $options.labels.accessExpireDate
      }}</label>
      <div class="gl-mt-2 gl-w-half gl-xs-w-full gl-display-inline-block">
        <gl-datepicker
          v-model="selectedDate"
          class="gl-display-inline!"
          :min-date="new Date()"
          :target="null"
        >
          <template #default="{ formattedDate }">
            <gl-form-input
              class="gl-w-full"
              :value="formattedDate"
              :placeholder="__(`YYYY-MM-DD`)"
            />
          </template>
        </gl-datepicker>
      </div>
    </div>

    <template #modal-footer>
      <div class="gl-display-flex gl-flex-direction-row gl-justify-content-end gl-flex-wrap gl-p-3">
        <gl-button ref="cancelButton" @click="cancelInvite">
          {{ $options.labels.cancelButtonText }}
        </gl-button>
        <div class="gl-mr-3"></div>
        <gl-button
          ref="inviteButton"
          :disabled="!newUsersToInvite"
          variant="success"
          @click="sendInvite"
          >{{ $options.labels.inviteButtonText }}</gl-button
        >
      </div>
    </template>
  </gl-modal>
</template>
