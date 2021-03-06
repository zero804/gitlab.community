<script>
import Vue from 'vue';
import { memoize, isString, cloneDeep, isNumber } from 'lodash';
import {
  GlDeprecatedButton,
  GlBadge,
  GlTooltip,
  GlTooltipDirective,
  GlFormTextarea,
  GlFormCheckbox,
  GlSprintf,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import featureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import ToggleButton from '~/vue_shared/components/toggle_button.vue';
import Icon from '~/vue_shared/components/icon.vue';
import EnvironmentsDropdown from './environments_dropdown.vue';
import Strategy from './strategy.vue';
import {
  ROLLOUT_STRATEGY_ALL_USERS,
  ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
  ROLLOUT_STRATEGY_USER_ID,
  ALL_ENVIRONMENTS_NAME,
  INTERNAL_ID_PREFIX,
  NEW_VERSION_FLAG,
  LEGACY_FLAG,
} from '../constants';
import { createNewEnvironmentScope } from '../store/modules/helpers';

export default {
  components: {
    GlDeprecatedButton,
    GlBadge,
    GlFormTextarea,
    GlFormCheckbox,
    GlTooltip,
    GlSprintf,
    ToggleButton,
    Icon,
    EnvironmentsDropdown,
    Strategy,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [featureFlagsMixin()],
  props: {
    active: {
      type: Boolean,
      required: false,
      default: true,
    },
    name: {
      type: String,
      required: false,
      default: '',
    },
    description: {
      type: String,
      required: false,
      default: '',
    },
    scopes: {
      type: Array,
      required: false,
      default: () => [],
    },
    cancelPath: {
      type: String,
      required: true,
    },
    submitText: {
      type: String,
      required: true,
    },
    environmentsEndpoint: {
      type: String,
      required: true,
    },
    strategies: {
      type: Array,
      required: false,
      default: () => [],
    },
    version: {
      type: String,
      required: false,
      default: LEGACY_FLAG,
    },
  },
  translations: {
    allEnvironmentsText: s__('FeatureFlags|* (All Environments)'),

    helpText: s__(
      'FeatureFlags|Feature Flag behavior is built up by creating a set of rules to define the status of target environments. A default wildcard rule %{codeStart}*%{codeEnd} for %{boldStart}All Environments%{boldEnd} is set, and you are able to add as many rules as you need by choosing environment specs below. You can toggle the behavior for each of your rules to set them %{boldStart}Active%{boldEnd} or %{boldStart}Inactive%{boldEnd}.',
    ),

    newHelpText: s__(
      'FeatureFlags|Enable features for specific users and specific environments by defining feature flag strategies. By default, features are available to all users in all environments.',
    ),
    noStrategiesText: s__('FeatureFlags|Feature Flag has no strategies'),
  },

  ROLLOUT_STRATEGY_ALL_USERS,
  ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
  ROLLOUT_STRATEGY_USER_ID,

  // Matches numbers 0 through 100
  rolloutPercentageRegex: /^[0-9]$|^[1-9][0-9]$|^100$/,

  data() {
    return {
      formName: this.name,
      formDescription: this.description,

      // operate on a clone to avoid mutating props
      formScopes: this.scopes.map(s => ({ ...s })),
      formStrategies: cloneDeep(this.strategies),

      newScope: '',
    };
  },
  computed: {
    filteredScopes() {
      return this.formScopes.filter(scope => !scope.shouldBeDestroyed);
    },
    filteredStrategies() {
      return this.formStrategies.filter(s => !s.shouldBeDestroyed);
    },
    canUpdateFlag() {
      return !this.permissionsFlag || (this.formScopes || []).every(scope => scope.canUpdate);
    },
    permissionsFlag() {
      return this.glFeatures.featureFlagPermissions;
    },
    supportsStrategies() {
      return this.glFeatures.featureFlagsNewVersion && this.version === NEW_VERSION_FLAG;
    },

    canDeleteStrategy() {
      return this.formStrategies.length > 1;
    },
  },
  methods: {
    addStrategy() {
      this.formStrategies.push({ name: '', parameters: {}, scopes: [] });
    },

    deleteStrategy(s) {
      if (isNumber(s.id)) {
        Vue.set(s, 'shouldBeDestroyed', true);
      } else {
        this.formStrategies = this.formStrategies.filter(strategy => strategy !== s);
      }
    },

    isAllEnvironment(name) {
      return name === ALL_ENVIRONMENTS_NAME;
    },

    /**
     * When the user clicks the remove button we delete the scope
     *
     * If the scope has an ID, we need to add the `shouldBeDestroyed` flag.
     * If the scope does *not* have an ID, we can just remove it.
     *
     * This flag will be used when submitting the data to the backend
     * to determine which records to delete (via a "_destroy" property).
     *
     * @param {Object} scope
     */
    removeScope(scope) {
      if (isString(scope.id) && scope.id.startsWith(INTERNAL_ID_PREFIX)) {
        this.formScopes = this.formScopes.filter(s => s !== scope);
      } else {
        Vue.set(scope, 'shouldBeDestroyed', true);
      }
    },

    /**
     * Creates a new scope and adds it to the list of scopes
     *
     * @param overrides An object whose properties will
     * be used override the default scope options
     */
    createNewScope(overrides) {
      this.formScopes.push(createNewEnvironmentScope(overrides, this.permissionsFlag));
      this.newScope = '';
    },

    /**
     * When the user clicks the submit button
     * it triggers an event with the form data
     */
    handleSubmit() {
      const flag = {
        name: this.formName,
        description: this.formDescription,
        active: this.active,
        version: this.version,
      };

      if (this.version === LEGACY_FLAG) {
        flag.scopes = this.formScopes;
      } else {
        flag.strategies = this.formStrategies;
      }

      this.$emit('handleSubmit', flag);
    },

    canUpdateScope(scope) {
      return !this.permissionsFlag || scope.canUpdate;
    },

    isRolloutPercentageInvalid: memoize(function isRolloutPercentageInvalid(percentage) {
      return !this.$options.rolloutPercentageRegex.test(percentage);
    }),

    /**
     * Generates a unique ID for the strategy based on the v-for index
     *
     * @param index The index of the strategy
     */
    rolloutStrategyId(index) {
      return `rollout-strategy-${index}`;
    },

    /**
     * Generates a unique ID for the percentage based on the v-for index
     *
     * @param index The index of the percentage
     */
    rolloutPercentageId(index) {
      return `rollout-percentage-${index}`;
    },
    rolloutUserId(index) {
      return `rollout-user-id-${index}`;
    },

    shouldDisplayIncludeUserIds(scope) {
      return ![ROLLOUT_STRATEGY_ALL_USERS, ROLLOUT_STRATEGY_USER_ID].includes(
        scope.rolloutStrategy,
      );
    },
    shouldDisplayUserIds(scope) {
      return scope.rolloutStrategy === ROLLOUT_STRATEGY_USER_ID || scope.shouldIncludeUserIds;
    },
    onStrategyChange(index) {
      const scope = this.filteredScopes[index];
      scope.shouldIncludeUserIds =
        scope.rolloutUserIds.length > 0 &&
        scope.rolloutStrategy === ROLLOUT_STRATEGY_PERCENT_ROLLOUT;
    },
    onFormStrategyChange({ id, name, parameters, scopes }, index) {
      Object.assign(this.filteredStrategies[index], {
        id,
        name,
        parameters,
        scopes,
      });
    },
  },
};
</script>
<template>
  <form class="feature-flags-form">
    <fieldset>
      <div class="row">
        <div class="form-group col-md-4">
          <label for="feature-flag-name" class="label-bold">{{ s__('FeatureFlags|Name') }} *</label>
          <input
            id="feature-flag-name"
            v-model="formName"
            :disabled="!canUpdateFlag"
            class="form-control"
          />
        </div>
      </div>

      <div class="row">
        <div class="form-group col-md-4">
          <label for="feature-flag-description" class="label-bold">
            {{ s__('FeatureFlags|Description') }}
          </label>
          <textarea
            id="feature-flag-description"
            v-model="formDescription"
            :disabled="!canUpdateFlag"
            class="form-control"
            rows="4"
          ></textarea>
        </div>
      </div>

      <template v-if="supportsStrategies">
        <div class="row">
          <div class="col-md-12">
            <h4>{{ s__('FeatureFlags|Strategies') }}</h4>
            <div class="flex align-items-baseline justify-content-between">
              <p class="mr-3">{{ $options.translations.newHelpText }}</p>
              <gl-deprecated-button variant="success" category="secondary" @click="addStrategy">
                {{ s__('FeatureFlags|Add strategy') }}
              </gl-deprecated-button>
            </div>
          </div>
        </div>
        <template v-if="filteredStrategies.length > 0">
          <strategy
            v-for="(strategy, index) in filteredStrategies"
            :key="strategy.id"
            :strategy="strategy"
            :index="index"
            :endpoint="environmentsEndpoint"
            :can-delete="canDeleteStrategy"
            @change="onFormStrategyChange($event, index)"
            @delete="deleteStrategy(strategy)"
          />
        </template>
        <div v-else class="flex justify-content-center border-top py-4 w-100">
          <span>{{ $options.translations.noStrategiesText }}</span>
        </div>
      </template>

      <div v-else class="row">
        <div class="form-group col-md-12">
          <h4>{{ s__('FeatureFlags|Target environments') }}</h4>
          <gl-sprintf :message="$options.translations.helpText">
            <template #code="{ content }">
              <code>{{ content }}</code>
            </template>
            <template #bold="{ content }">
              <b>{{ content }}</b>
            </template>
          </gl-sprintf>

          <div class="js-scopes-table prepend-top-default">
            <div class="gl-responsive-table-row table-row-header" role="row">
              <div class="table-section section-30" role="columnheader">
                {{ s__('FeatureFlags|Environment Spec') }}
              </div>
              <div class="table-section section-20 text-center" role="columnheader">
                {{ s__('FeatureFlags|Status') }}
              </div>
              <div class="table-section section-40" role="columnheader">
                {{ s__('FeatureFlags|Rollout Strategy') }}
              </div>
            </div>

            <div
              v-for="(scope, index) in filteredScopes"
              :key="scope.id"
              ref="scopeRow"
              class="gl-responsive-table-row"
              role="row"
            >
              <div class="table-section section-30" role="gridcell">
                <div class="table-mobile-header" role="rowheader">
                  {{ s__('FeatureFlags|Environment Spec') }}
                </div>
                <div
                  class="table-mobile-content js-feature-flag-status d-flex align-items-center justify-content-start"
                >
                  <p v-if="isAllEnvironment(scope.environmentScope)" class="js-scope-all pl-3">
                    {{ $options.translations.allEnvironmentsText }}
                  </p>

                  <environments-dropdown
                    v-else
                    class="col-12"
                    :value="scope.environmentScope"
                    :endpoint="environmentsEndpoint"
                    :disabled="!canUpdateScope(scope)"
                    @selectEnvironment="env => (scope.environmentScope = env)"
                    @createClicked="env => (scope.environmentScope = env)"
                    @clearInput="env => (scope.environmentScope = '')"
                  />

                  <gl-badge v-if="permissionsFlag && scope.protected" variant="success">
                    {{ s__('FeatureFlags|Protected') }}
                  </gl-badge>
                </div>
              </div>

              <div class="table-section section-20 text-center" role="gridcell">
                <div class="table-mobile-header" role="rowheader">
                  {{ s__('FeatureFlags|Status') }}
                </div>
                <div class="table-mobile-content js-feature-flag-status">
                  <toggle-button
                    :value="scope.active"
                    :disabled-input="!active || !canUpdateScope(scope)"
                    @change="status => (scope.active = status)"
                  />
                </div>
              </div>

              <div class="table-section section-40" role="gridcell">
                <div class="table-mobile-header" role="rowheader">
                  {{ s__('FeatureFlags|Rollout Strategy') }}
                </div>
                <div class="table-mobile-content js-rollout-strategy form-inline">
                  <label class="sr-only" :for="rolloutStrategyId(index)">
                    {{ s__('FeatureFlags|Rollout Strategy') }}
                  </label>
                  <div class="select-wrapper col-12 col-md-8 p-0">
                    <select
                      :id="rolloutStrategyId(index)"
                      v-model="scope.rolloutStrategy"
                      :disabled="!scope.active"
                      class="form-control select-control w-100 js-rollout-strategy"
                      @change="onStrategyChange(index)"
                    >
                      <option :value="$options.ROLLOUT_STRATEGY_ALL_USERS">
                        {{ s__('FeatureFlags|All users') }}
                      </option>
                      <option :value="$options.ROLLOUT_STRATEGY_PERCENT_ROLLOUT">
                        {{ s__('FeatureFlags|Percent rollout (logged in users)') }}
                      </option>
                      <option :value="$options.ROLLOUT_STRATEGY_USER_ID">
                        {{ s__('FeatureFlags|User IDs') }}
                      </option>
                    </select>
                    <i aria-hidden="true" data-hidden="true" class="fa fa-chevron-down"></i>
                  </div>

                  <div
                    v-if="scope.rolloutStrategy === $options.ROLLOUT_STRATEGY_PERCENT_ROLLOUT"
                    class="d-flex-center mt-2 mt-md-0 ml-md-2"
                  >
                    <label class="sr-only" :for="rolloutPercentageId(index)">
                      {{ s__('FeatureFlags|Rollout Percentage') }}
                    </label>
                    <div class="w-3rem">
                      <input
                        :id="rolloutPercentageId(index)"
                        v-model="scope.rolloutPercentage"
                        :disabled="!scope.active"
                        :class="{
                          'is-invalid': isRolloutPercentageInvalid(scope.rolloutPercentage),
                        }"
                        type="number"
                        min="0"
                        max="100"
                        :pattern="$options.rolloutPercentageRegex.source"
                        class="rollout-percentage js-rollout-percentage form-control text-right w-100"
                      />
                    </div>
                    <gl-tooltip
                      v-if="isRolloutPercentageInvalid(scope.rolloutPercentage)"
                      :target="rolloutPercentageId(index)"
                    >
                      {{
                        s__('FeatureFlags|Percent rollout must be a whole number between 0 and 100')
                      }}
                    </gl-tooltip>
                    <span class="ml-1">%</span>
                  </div>
                  <div class="d-flex flex-column align-items-start mt-2 w-100">
                    <gl-form-checkbox
                      v-if="shouldDisplayIncludeUserIds(scope)"
                      v-model="scope.shouldIncludeUserIds"
                    >
                      {{ s__('FeatureFlags|Include additional user IDs') }}
                    </gl-form-checkbox>
                    <template v-if="shouldDisplayUserIds(scope)">
                      <label :for="rolloutUserId(index)" class="mb-2">
                        {{ s__('FeatureFlags|User IDs') }}
                      </label>
                      <gl-form-textarea
                        :id="rolloutUserId(index)"
                        v-model="scope.rolloutUserIds"
                        class="w-100"
                      />
                    </template>
                  </div>
                </div>
              </div>

              <div class="table-section section-10 text-right" role="gridcell">
                <div class="table-mobile-header" role="rowheader">
                  {{ s__('FeatureFlags|Remove') }}
                </div>
                <div class="table-mobile-content js-feature-flag-delete">
                  <gl-deprecated-button
                    v-if="!isAllEnvironment(scope.environmentScope) && canUpdateScope(scope)"
                    v-gl-tooltip
                    :title="s__('FeatureFlags|Remove')"
                    class="js-delete-scope btn-transparent pr-3 pl-3"
                    @click="removeScope(scope)"
                  >
                    <icon name="clear" />
                  </gl-deprecated-button>
                </div>
              </div>
            </div>

            <div class="js-add-new-scope gl-responsive-table-row" role="row">
              <div class="table-section section-30" role="gridcell">
                <div class="table-mobile-header" role="rowheader">
                  {{ s__('FeatureFlags|Environment Spec') }}
                </div>
                <div class="table-mobile-content js-feature-flag-status">
                  <environments-dropdown
                    class="js-new-scope-name col-12"
                    :endpoint="environmentsEndpoint"
                    :value="newScope"
                    @selectEnvironment="env => createNewScope({ environmentScope: env })"
                    @createClicked="env => createNewScope({ environmentScope: env })"
                  />
                </div>
              </div>

              <div class="table-section section-20 text-center" role="gridcell">
                <div class="table-mobile-header" role="rowheader">
                  {{ s__('FeatureFlags|Status') }}
                </div>
                <div class="table-mobile-content js-feature-flag-status">
                  <toggle-button
                    :disabled-input="!active"
                    :value="false"
                    @change="createNewScope({ active: true })"
                  />
                </div>
              </div>

              <div class="table-section section-40" role="gridcell">
                <div class="table-mobile-header" role="rowheader">
                  {{ s__('FeatureFlags|Rollout Strategy') }}
                </div>
                <div class="table-mobile-content js-rollout-strategy form-inline">
                  <label class="sr-only" for="new-rollout-strategy-placeholder">{{
                    s__('FeatureFlags|Rollout Strategy')
                  }}</label>
                  <div class="select-wrapper col-12 col-md-8 p-0">
                    <select
                      id="new-rollout-strategy-placeholder"
                      disabled
                      class="form-control select-control w-100"
                    >
                      <option>{{ s__('FeatureFlags|All users') }}</option>
                    </select>
                    <i aria-hidden="true" data-hidden="true" class="fa fa-chevron-down"></i>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </fieldset>

    <div class="form-actions">
      <gl-deprecated-button
        ref="submitButton"
        type="button"
        variant="success"
        class="js-ff-submit col-xs-12"
        @click="handleSubmit"
      >
        {{ submitText }}
      </gl-deprecated-button>
      <gl-deprecated-button
        :href="cancelPath"
        variant="secondary"
        class="js-ff-cancel col-xs-12 float-right"
      >
        {{ __('Cancel') }}
      </gl-deprecated-button>
    </div>
  </form>
</template>
