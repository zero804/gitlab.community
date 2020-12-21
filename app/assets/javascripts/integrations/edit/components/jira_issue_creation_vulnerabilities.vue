<script>
import { mapState } from 'vuex';
import {
  GlButton,
  GlButtonGroup,
  GlDropdown,
  GlDropdownItem,
  GlFormCheckbox,
  GlFormGroup,
  GlIcon,
} from '@gitlab/ui';

import eventHub from '../event_hub';

export default {
  components: {
    GlButton,
    GlButtonGroup,
    GlDropdown,
    GlDropdownItem,
    GlFormCheckbox,
    GlFormGroup,
    GlIcon,
  },
  props: {
    initialIsEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    hasProjectKey: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      // @TODO: set the initial value to be passed in via a prop
      // @TODO: rename this
      isEnabled: this.initialIsEnabled,
      selectedIssueType: {},
    };
  },
  computed: {
    ...mapState(['isTesting', 'jiraIssueTypes', 'isLoadingJiraIssueTypes']),
  },
  methods: {
    handleLoadJiraIssueTypesClick() {
      eventHub.$emit('getJiraIssueTypes');
    },
  },
};
</script>

<template>
  <div>
    <gl-form-checkbox v-model="isEnabled">
      {{ s__('JiraService|Enable Jira issues creation from vulnerabilities') }}
      <template #help>
        {{
          s__(
            'JiraService|Issues created from vulnerabilities in this project will be Jira issues, even if GitLab issues are enabled.',
          )
        }}
      </template>
    </gl-form-checkbox>
    <input name="service[vulnerabilities_enabled]" type="hidden" :value="isEnabled || false" />
    <gl-form-group
      v-show="isEnabled"
      :label="__('Jira issue type')"
      class="gl-mt-4 gl-pl-1 gl-ml-5"
    >
      <p>{{ __('Define the type of Jira issue to create from a vulnerability.') }}</p>
      <div class="gl-display-flex gl-align-items-center">
        <gl-button-group class="gl-mr-3">
          <gl-dropdown
            :disabled="!hasProjectKey"
            :loading="isLoadingJiraIssueTypes || isTesting"
            :text="selectedIssueType.name || __('Select issue type')"
          >
            <gl-dropdown-item
              v-for="jiraIssueType in jiraIssueTypes"
              :key="jiraIssueType.id"
              :is-checked="jiraIssueType === selectedIssueType"
              @click="selectedIssueType = jiraIssueType"
            >
              {{ jiraIssueType.name }}
            </gl-dropdown-item>
          </gl-dropdown>
          <gl-button
            :disabled="!hasProjectKey"
            icon="retry"
            @click="handleLoadJiraIssueTypesClick"
          />
        </gl-button-group>
        <p v-if="!hasProjectKey" class="gl-my-0">
          <gl-icon name="warning" class="gl-text-orange-500" />
          {{ __('Project key is required to generate issue types') }}
        </p>
      </div>
    </gl-form-group>
  </div>
</template>
