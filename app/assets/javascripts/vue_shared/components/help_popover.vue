<script>
import { GlIcon, GlPopover } from '@gitlab/ui';

/**
 * Render a button with a question mark icon
 * On hover shows a popover. The popover will be dismissed on mouseleave
 */
export default {
  name: 'HelpPopover',
  components: {
    GlIcon, GlPopover,
  },
  props: {
    options: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  
};
</script>
<template>
  <span>
    <button ref="popoverTrigger" type="button" class="btn btn-blank btn-transparent btn-help" tabindex="0">
      <gl-icon name="question" />
    </button>
    <gl-popover triggers="hover focus" :target="() => $refs.popoverTrigger">
      <template #title>{{options.title}}</template>
      {{options.content}}
    </gl-popover>
  </span>

</template>