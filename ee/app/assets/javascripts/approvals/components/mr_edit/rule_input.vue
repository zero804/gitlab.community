<script>
import { mapState, mapActions } from 'vuex';
import { RULE_TYPE_ANY_APPROVER } from '../../constants';
import { debounce } from 'lodash';

const ANY_RULE_NAME = 'All Members';

export default {
  props: {
    rule: {
      type: Object,
      required: true,
    },
    isMrEdit: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    ...mapState(['settings']),
  },
  methods: {
    ...mapActions(['putRule', 'postRule']),
    onInputChange: debounce(function debounceSearch(event) {
      const { value } = event.target;
      const approvalsRequired = parseInt(value, 10);

      if (this.rule.id) {
        this.putRule({ id: this.rule.id, approvalsRequired });
      } else {
        this.postRule({
          name: ANY_RULE_NAME,
          ruleType: RULE_TYPE_ANY_APPROVER,
          approvalsRequired,
        });
      }
    }, 1000),
  },
};
</script>

<template>
  <input
    :value="rule.approvalsRequired"
    :disabled="!settings.canEdit"
    class="form-control mw-6em"
    type="number"
    :min="rule.minApprovalsRequired || 0"
    @input="onInputChange"
  />
</template>
