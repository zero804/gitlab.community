<script>
import {
  GlButton,
  GlButtonGroup,
  GlDropdown,
  GlDropdownItem,
  GlFormCheckbox,
  GlFormGroup,
  GlIcon,
} from '@gitlab/ui';

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
    hasProjectKey: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      // @TODO: set the initial value to be passed in via a prop
      // @TODO: rename this
      isEnabled: true,
    };
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
    <gl-form-group v-if="isEnabled" :label="__('Jira issue type')" class="gl-mt-4 gl-pl-1 gl-ml-5">
      <p>{{ __('Define the type of Jira issue to create from a vulnerability.') }}</p>
      <div class="gl-display-flex gl-align-items-center">
        <gl-button-group class="gl-mr-3">
          <gl-dropdown :disabled="!hasProjectKey" :text="__('Select issue type')">
            <gl-dropdown-item>{{ __('Pizza') }}</gl-dropdown-item></gl-dropdown
          >
          <gl-button :disabled="!hasProjectKey" icon="retry" />
        </gl-button-group>
        <p v-if="!hasProjectKey" class="gl-my-0">
          <gl-icon name="warning" class="gl-text-orange-500" />
          {{ __('Project key is required to generate issue types') }}
        </p>
      </div>
    </gl-form-group>
  </div>
</template>
