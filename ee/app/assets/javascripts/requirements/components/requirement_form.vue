<script>
import { GlFormGroup, GlFormTextarea, GlDeprecatedButton } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { __, sprintf } from '~/locale';

import { MAX_TITLE_LENGTH } from '../constants';

export default {
  titleInvalidMessage: sprintf(__('Requirement title cannot have more than %{limit} characters.'), {
    limit: MAX_TITLE_LENGTH,
  }),
  components: {
    GlFormGroup,
    GlFormTextarea,
    GlDeprecatedButton,
  },
  props: {
    requirement: {
      type: Object,
      required: false,
      default: null,
    },
    requirementRequestActive: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      isCreate: isEmpty(this.requirement),
      title: this.requirement?.title || '',
    };
  },
  computed: {
    fieldLabel() {
      return this.isCreate ? __('New requirement') : __('Requirement');
    },
    saveButtonLabel() {
      return this.isCreate ? __('Create requirement') : __('Save changes');
    },
    titleInvalid() {
      return this.title.length > MAX_TITLE_LENGTH;
    },
    disableSaveButton() {
      return this.title === '' || this.titleInvalid || this.requirementRequestActive;
    },
    reference() {
      return `REQ-${this.requirement?.iid}`;
    },
  },
  methods: {
    handleSave() {
      if (this.isCreate) {
        this.$emit('save', this.title);
      } else {
        this.$emit('save', {
          iid: this.requirement.iid,
          title: this.title,
        });
      }
    },
  },
};
</script>

<template>
  <div
    class="requirement-form"
    :class="{ 'p-3 border-bottom': isCreate, 'd-block d-sm-flex': !isCreate }"
  >
    <span v-if="!isCreate" class="text-muted mr-1">{{ reference }}</span>
    <div class="requirement-form-container" :class="{ 'flex-grow-1 ml-sm-1 mt-1': !isCreate }">
      <gl-form-group
        :label="fieldLabel"
        :invalid-feedback="$options.titleInvalidMessage"
        :state="!titleInvalid"
        class="gl-show-field-errors"
        label-for="requirementTitle"
      >
        <gl-form-textarea
          id="requirementTitle"
          v-model.trim="title"
          autofocus
          resize
          :disabled="requirementRequestActive"
          :placeholder="__('Describe the requirement here')"
          max-rows="25"
          class="requirement-form-textarea"
          :class="{ 'gl-field-error-outline': titleInvalid }"
          @keyup.escape.exact="$emit('cancel')"
        />
      </gl-form-group>
      <div class="d-flex requirement-form-actions">
        <gl-deprecated-button
          :disabled="disableSaveButton"
          :loading="requirementRequestActive"
          category="primary"
          variant="success"
          class="mr-auto js-requirement-save"
          @click="handleSave"
          >{{ saveButtonLabel }}</gl-deprecated-button
        >
        <gl-deprecated-button class="js-requirement-cancel" @click="$emit('cancel')">{{
          __('Cancel')
        }}</gl-deprecated-button>
      </div>
    </div>
  </div>
</template>
