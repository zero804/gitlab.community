<script>
import { mapState } from 'vuex';
import {
  GlAlert,
  GlButton,
  GlButtonGroup,
  GlDropdown,
  GlDropdownItem,
  GlFormCheckbox,
  GlFormGroup,
  GlIcon,
  GlTooltipDirective,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import eventHub from '../event_hub';
import { defaultJiraIssueTypeId } from '../constants';

export default {
  components: {
    GlAlert,
    GlButton,
    GlButtonGroup,
    GlDropdown,
    GlDropdownItem,
    GlFormCheckbox,
    GlFormGroup,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    projectKey: {
      type: String,
      required: false,
      default: '',
    },
    initialIssueTypeId: {
      type: String,
      required: false,
      default: defaultJiraIssueTypeId,
    },
    initialIsEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isLoadingErrorAlertDimissed: false,
      projectKeyForCurrentIssues: '',
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
    hasProjectKeyChanged() {
      return this.projectKeyForCurrentIssues && this.projectKey !== this.projectKeyForCurrentIssues;
    },
    shouldShowLoadingErrorAlert() {
      return !this.isLoadingErrorAlertDimissed && this.loadingJiraIssueTypesErrorMessage;
    },
    projectKeyWarning() {
      if (!this.projectKey) {
        return s__('JiraService|Project key is required to generate issue types');
      }
      if (this.hasProjectKeyChanged) {
        return s__('JiraService|Project key changed, refresh list');
      }
      return '';
    },
  },
  mounted() {
    eventHub.$once('formInitialized', () => {
      eventHub.$emit('getJiraIssueTypes');
    });
  },
  methods: {
    handleLoadJiraIssueTypesClick() {
      this.projectKeyForCurrentIssues = this.projectKey;
      eventHub.$emit('getJiraIssueTypes');
      this.isLoadingErrorAlertDimissed = false;
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
      :value="isJiraVulnerabilitiesEnabled"
    />
    <gl-form-group
      v-show="isJiraVulnerabilitiesEnabled"
      :label="s__('JiraService|Jira issue type')"
      class="gl-mt-4 gl-pl-1 gl-ml-5"
    >
      <p>{{ s__('JiraService|Define the type of Jira issue to create from a vulnerability.') }}</p>
      <gl-alert
        v-if="shouldShowLoadingErrorAlert"
        class="gl-mb-5"
        variant="danger"
        :title="s__('JiraService|An error occured while fetching issue list')"
        @dismiss="isLoadingErrorAlertDimissed = true"
      >
        {{ loadingJiraIssueTypesErrorMessage }}
      </gl-alert>
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
            v-gl-tooltip
            :title="s__('JiraService|Fetch issue types for this jira project')"
            :disabled="!projectKey"
            icon="retry"
            @click="handleLoadJiraIssueTypesClick"
          />
        </gl-button-group>
        <p v-if="projectKeyWarning" class="gl-my-0">
          <gl-icon name="warning" class="gl-text-orange-500" />
          {{ projectKeyWarning }}
        </p>
      </div>
    </gl-form-group>
  </div>
</template>
