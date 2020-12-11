<script>
import { GlFormText, GlIcon, GlLink, GlSprintf } from '@gitlab/ui';
import IntegrationView from './integration_view.vue';
import { INTEGRATION_VIEW_CONFIGS, i18n } from '../constants';

export default {
  name: 'ProfilePreferences',
  components: {
    GlFormText,
    GlIcon,
    GlLink,
    GlSprintf,
    IntegrationView,
  },
  inject: {
    firstDayOfWeekChoicesWithDefault: 'firstDayOfWeekChoicesWithDefault',
    languageChoices: 'languageChoices',
    integrationViews: {
      default: [],
    },
    userFields: 'userFields',
    featureFlags: 'featureFlags',
  },
  data() {
    return {
      selectedPreferredLanguage: this.userFields.preferred_language,
      selectedFirstDayOfWeek: this.userFields.first_day_of_week,
      selectedTimeFormatIn24h: this.userFields.time_format_in_24h,
      selectedTimeDisplayRelative: this.userFields.time_display_relative,
    };
  },
  i18n,
  integrationViewConfigs: INTEGRATION_VIEW_CONFIGS,
};
</script>

<template>
  <div class="row gl-mt-3 js-preferences-form">
    <div class="col-sm-12">
      <hr />
    </div>
    <div id="localization" class="col-lg-4 profile-settings-sidebar">
      <h4 class="gl-mt-0">
        {{ $options.i18n.localization }}
      </h4>
      <p>
        {{ $options.i18n.localizationDescription }}
        <gl-sprintf :message="$options.i18n.learnMore">
          <template #link="{ content }">
            <gl-link
              class="gl-display-inline-block"
              href="/help/user/profile/preferences#localization"
              target="_blank"
            >
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </p>
    </div>
    <div class="col-lg-8">
      <div class="gl-form-group">
        <label class="gl-font-weight-bold" for="user_preferred_language">
          {{ $options.i18n.language }}
        </label>
        <div class="gl-relative">
          <select
            id="user_preferred_language"
            v-model="selectedPreferredLanguage"
            class="form-control select-control"
            name="user[preferred_language]"
            title="Language"
          >
            <option
              v-for="[optionName, optionValue] in languageChoices"
              :key="optionValue"
              data-testid="user-preferred-language-option"
              :value="optionValue"
            >
              {{ optionName }}
            </option>
          </select>
          <gl-icon
            name="chevron-down"
            data-hidden="true"
            class="gl-absolute gl-top-4 gl-right-3 gl-text-gray-200"
          />
        </div>
        <gl-form-text>
          {{ $options.i18n.experimentalDescription }}
        </gl-form-text>
      </div>
      <div class="gl-form-group">
        <label class="gl-font-weight-bold" for="user_first_day_of_week">
          {{ $options.i18n.firstDayOfTheWeek }}
        </label>
        <div class="gl-relative">
          <select
            id="user_first_day_of_week"
            v-model="selectedFirstDayOfWeek"
            class="form-control select-control"
            name="user[first_day_of_week]"
            title="First day of the week"
          >
            <option
              v-for="[optionName, optionValue] in firstDayOfWeekChoicesWithDefault"
              :key="optionValue"
              data-testid="user-first-day-of-week-option"
              :value="optionValue"
            >
              {{ optionName }}
            </option>
          </select>
          <gl-icon
            name="chevron-down"
            data-hidden="true"
            class="gl-absolute gl-top-4 gl-right-3 gl-text-gray-200"
          />
        </div>
      </div>
    </div>

    <div
      v-if="featureFlags.userTimeSettings"
      class="col-sm-12"
      data-testid="user-time-settings-rule"
    >
      <hr />
    </div>
    <div
      v-if="featureFlags.userTimeSettings"
      class="col-lg-4 profile-settings-sidebar"
      data-testid="user-time-settings-heading"
    >
      <h4 class="gl-mt-0">
        {{ $options.i18n.timePreferences }}
      </h4>
      <p>
        {{ $options.i18n.timePreferencesDescription }}
      </p>
    </div>
    <div v-if="featureFlags.userTimeSettings" class="col-lg-8">
      <h5>
        {{ $options.i18n.timeFormat }}
      </h5>
      <div class="gl-form-group gl-form-checkbox form-check">
        <input name="user[time_format_in_24h]" type="hidden" value="0" />
        <input
          id="user_time_format_in_24h"
          v-model="selectedTimeFormatIn24h"
          data-testid="user-time-format-option"
          class="form-check-input"
          name="user[time_format_in_24h]"
          type="checkbox"
          value="1"
        />
        <label class="form-check-label" for="user_time_format_in_24h">
          {{ $options.i18n.timeFormatLabel }}
        </label>
      </div>
      <h5>
        {{ $options.i18n.relativeTime }}
      </h5>
      <div class="gl-form-group gl-form-checkbox form-check">
        <input name="user[time_display_relative]" type="hidden" value="0" />
        <input
          id="user_time_display_relative"
          v-model="selectedTimeDisplayRelative"
          data-testid="user-time-relative-option"
          class="form-check-input"
          name="user[time_display_relative]"
          type="checkbox"
          value="1"
        />
        <label class="form-check-label" for="user_time_display_relative">
          {{ $options.i18n.relativeTimeLabel }}
          <p class="help-text">
            {{ $options.i18n.relativeTimeHelpText }}
          </p>
        </label>
      </div>
    </div>

    <div v-if="integrationViews.length" class="col-sm-12">
      <hr data-testid="profile-preferences-integrations-rule" />
    </div>
    <div v-if="integrationViews.length" class="col-lg-4 profile-settings-sidebar">
      <h4 class="gl-mt-0" data-testid="profile-preferences-integrations-heading">
        {{ $options.i18n.integrations }}
      </h4>
      <p>
        {{ $options.i18n.integrationsDescription }}
      </p>
    </div>
    <div v-if="integrationViews.length" class="col-lg-8">
      <integration-view
        v-for="view in integrationViews"
        :key="view.name"
        :help-link="view.help_link"
        :message="view.message"
        :message-url="view.message_url"
        :config="$options.integrationViewConfigs[view.name]"
      />
    </div>
  </div>
</template>
