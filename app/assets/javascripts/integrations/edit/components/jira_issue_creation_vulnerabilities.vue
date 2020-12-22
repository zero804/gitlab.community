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
import { defaultJiraIssueTypeId } from '../constants';

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
    initialIssueTypeId: {
      type: String,
      required: false,
      default: defaultJiraIssueTypeId,
    },
    hasProjectKey: {
      type: Boolean,
      required: false,
      default: false,
    },
    initialIsEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isJiraVulnerabilitiesEnabled: this.initialIsEnabled,
      selectedJiraIssueType: null,
    };
  },
  computed: {
    ...mapState([
      'isTesting',
      'jiraIssueTypes',
      'isLoadingJiraIssueTypes',
      'loadingJiraIssueTypesErrorMessage',
    ]),
    initialJiraIssueType() {
      return this.jiraIssueTypes?.find(({ id }) => id === this.initialIssueTypeId) || {};
    },
    checkedIssueType() {
      return this.selectedJiraIssueType || this.initialJiraIssueType;
    },
  },
  mounted() {
    eventHub.$once('formInitialized', () => {
      eventHub.$emit('getJiraIssueTypes');
    });
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
    <gl-form-checkbox v-model="isJiraVulnerabilitiesEnabled">
      {{ s__('JiraService|Enable Jira issues creation from vulnerabilities') }}
      <template #help>
        {{
          s__(
            'JiraService|Issues created from vulnerabilities in this project will be Jira issues, even if GitLab issues are enabled.',
          )
        }}
      </template>
    </gl-form-checkbox>
    <input
      name="service[vulnerabilities_enabled]"
      type="hidden"
      :value="isJiraVulnerabilitiesEnabled || false"
    />
    <gl-form-group
      v-show="isJiraVulnerabilitiesEnabled"
      :label="s__('JiraService|Jira issue type')"
      class="gl-mt-4 gl-pl-1 gl-ml-5"
    >
      <p>{{ s__('JiraService|Define the type of Jira issue to create from a vulnerability.') }}</p>
      <div class="row gl-display-flex gl-align-items-center">
        <gl-button-group class="col-md-5 gl-mr-3">
          <input
            name="service[vulnerabilities_issuetype]"
            type="hidden"
            :value="checkedIssueType.id || initialIssueTypeId"
          />
          <gl-dropdown
            class="gl-w-full"
            :disabled="!jiraIssueTypes.length"
            :loading="isLoadingJiraIssueTypes || isTesting"
            :text="checkedIssueType.name || s__('JiraService|Select issue type')"
          >
            <gl-dropdown-item
              v-for="jiraIssueType in jiraIssueTypes"
              :key="jiraIssueType.id"
              :is-checked="checkedIssueType.id === jiraIssueType.id"
              is-check-item
              @click="selectedJiraIssueType = jiraIssueType"
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
        <p v-if="!hasProjectKey || loadingJiraIssueTypesErrorMessage" class="gl-my-0">
          <gl-icon name="warning" class="gl-text-orange-500" />
          {{
            !hasProjectKey
              ? s__('JiraService|Project key is required to generate issue types')
              : loadingJiraIssueTypesErrorMessage
          }}
        </p>
      </div>
    </gl-form-group>
  </div>
</template>
