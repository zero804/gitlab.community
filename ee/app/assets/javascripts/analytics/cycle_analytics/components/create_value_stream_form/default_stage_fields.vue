<script>
import { GlFormGroup, GlFormInput, GlFormText } from '@gitlab/ui';
import StageFieldActions from './stage_field_actions.vue';
import { I18N } from './constants';

export default {
  name: 'DefaultStageFields',
  components: {
    StageFieldActions,
    GlFormGroup,
    GlFormInput,
    GlFormText,
  },
  props: {
    index: {
      type: Number,
      required: true,
    },
    totalStages: {
      type: Number,
      required: true,
    },
    stage: {
      type: Object,
      required: true,
    },
    errors: {
      type: Object,
      required: false,
      default: () => {},
    },
  },
  methods: {
    isValid(field) {
      return !this.errors[field]?.length;
    },
    renderError(field) {
      return this.errors[field]?.join('\n');
    },
  },
  I18N,
};
</script>
<template>
  <div class="gl-mb-4">
    <div class="gl-display-flex">
      <gl-form-group
        class="gl-flex-grow-1 gl-mb-0"
        :state="isValid('name')"
        :invalid-feedback="renderError('name')"
      >
        <gl-form-input
          v-model.trim="stage.name"
          :name="`create-value-stream-stage-${index}`"
          :placeholder="$options.I18N.FIELD_STAGE_NAME_PLACEHOLDER"
          required
          @input="$emit('input', $event)"
        />
      </gl-form-group>
      <stage-field-actions
        :index="index"
        :stage-count="totalStages"
        @move="$emit('move', $event)"
        @hide="$emit('hide', $event)"
      />
    </div>
    <div class="gl-display-flex">
      <label class="gl-m-0 gl-vertical-align-middle gl-mr-3">{{ __('Start event: ') }}</label>
      <gl-form-text>{{ stage.startEventIdentifier }}</gl-form-text>
      <gl-form-text v-if="stage.startEventLabel"
        >&nbsp;-&nbsp;{{ stage.startEventLabel }}</gl-form-text
      >
    </div>
    <div class="gl-display-flex">
      <label class="gl-m-0 gl-vertical-align-middle gl-mr-3">{{ __('End event: ') }}</label>
      <gl-form-text>{{ stage.endEventIdentifier }}</gl-form-text>
      <gl-form-text v-if="stage.endEventLabel">&nbsp;-&nbsp;{{ stage.endEventLabel }}</gl-form-text>
    </div>
  </div>
</template>
