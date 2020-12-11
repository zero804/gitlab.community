import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import ProfilePreferences from '~/profile/preferences/components/profile_preferences.vue';
import IntegrationView from '~/profile/preferences/components/integration_view.vue';
import {
  languageChoices,
  firstDayOfWeekChoicesWithDefault,
  integrationViews,
  userFields,
  featureFlags,
} from '../mock_data';

describe('ProfilePreferences component', () => {
  let wrapper;
  const defaultProvide = {
    languageChoices,
    firstDayOfWeekChoicesWithDefault,
    integrationViews: [],
    userFields,
    featureFlags: {},
  };

  function createComponent(options = {}) {
    const { props = {}, provide = {} } = options;
    return shallowMount(ProfilePreferences, {
      provide: {
        ...defaultProvide,
        ...provide,
      },
      propsData: props,
      stubs: {
        GlSprintf,
      },
    });
  }

  function findLocalizationAnchor() {
    return wrapper.find('#localization');
  }

  function findUserLanguageOptionList() {
    return wrapper.findAll('[data-testid="user-preferred-language-option"]');
  }

  function findUserLanguageSelectedOption() {
    return wrapper.find('[data-testid="user-preferred-language-option"]:checked');
  }

  function findUserFirstDayOfWeekOptionList() {
    return wrapper.findAll('[data-testid="user-first-day-of-week-option"]');
  }

  function findUserFirstDayOfWeekSelectedOption() {
    return wrapper.find('[data-testid="user-first-day-of-week-option"]:checked');
  }

  function findUserTimeSettingsRule() {
    return wrapper.find('[data-testid="user-time-settings-rule"]');
  }

  function findUserTimeSettingsHeading() {
    return wrapper.find('[data-testid="user-time-settings-heading"]');
  }

  function findUserTimeFormatOption() {
    return wrapper.find('[data-testid="user-time-format-option"]');
  }

  function findUserTimeRelativeOption() {
    return wrapper.find('[data-testid="user-time-relative-option"]');
  }

  function findIntegrationsRule() {
    return wrapper.find('[data-testid="profile-preferences-integrations-rule"]');
  }

  function findIntegrationsHeading() {
    return wrapper.find('[data-testid="profile-preferences-integrations-heading"]');
  }

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('Localization Settings section', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('has an id for anchoring', () => {
      expect(findLocalizationAnchor().exists()).toBe(true);
    });

    it('allows the user to change their language preferences', async () => {
      const newChoice = 1;
      const languageOptions = findUserLanguageOptionList();
      expect(findUserLanguageSelectedOption().element.value).toBe(languageChoices[0][1]);
      await languageOptions.at(newChoice).setSelected();
      expect(findUserLanguageSelectedOption().element.value).toBe(languageChoices[newChoice][1]);
    });

    it('allows the user to change their first day of the week preferences', async () => {
      const newChoice = 1;
      const languageOptions = findUserFirstDayOfWeekOptionList();
      expect(findUserFirstDayOfWeekSelectedOption().element.value).toBe(
        firstDayOfWeekChoicesWithDefault[0][1],
      );
      await languageOptions.at(newChoice).setSelected();
      expect(findUserFirstDayOfWeekSelectedOption().element.value).toBe(
        firstDayOfWeekChoicesWithDefault[newChoice][1],
      );
    });
  });

  describe('with `userTimeSettings` feature flag enabled', () => {
    beforeEach(() => {
      wrapper = createComponent({ provide: { featureFlags } });
    });

    it('should render user time settings', () => {
      const userTimeSettingsRule = findUserTimeSettingsRule();
      const userTimeSettingsHeading = findUserTimeSettingsHeading();
      const userTimeFormatOption = findUserTimeFormatOption();
      const userTimeTimeRelativeOption = findUserTimeRelativeOption();
      expect(userTimeSettingsRule.exists()).toBe(true);
      expect(userTimeSettingsHeading.exists()).toBe(true);
      expect(userTimeFormatOption.exists()).toBe(true);
      expect(userTimeTimeRelativeOption.exists()).toBe(true);
    });

    it('allows the user to toggle their time format preference', () => {
      const userTimeFormatOption = findUserTimeFormatOption();
      expect(userTimeFormatOption.element.checked).toBe(false);
      userTimeFormatOption.trigger('click');
      expect(userTimeFormatOption.element.checked).toBe(true);
    });

    it('allows the user to toggle their time display preference', () => {
      const userTimeTimeRelativeOption = findUserTimeRelativeOption();
      expect(userTimeTimeRelativeOption.element.checked).toBe(false);
      userTimeTimeRelativeOption.trigger('click');
      expect(userTimeTimeRelativeOption.element.checked).toBe(true);
    });
  });

  describe('with `userTimeSettings` feature flag disabled', () => {
    it('should not render user time settings', () => {
      wrapper = createComponent();
      const userTimeSettingsRule = findUserTimeSettingsRule();
      const userTimeSettingsHeading = findUserTimeSettingsHeading();
      const userTimeFormatOption = findUserTimeFormatOption();
      const userTimeTimeRelativeOption = findUserTimeRelativeOption();
      expect(userTimeSettingsRule.exists()).toBe(false);
      expect(userTimeSettingsHeading.exists()).toBe(false);
      expect(userTimeFormatOption.exists()).toBe(false);
      expect(userTimeTimeRelativeOption.exists()).toBe(false);
    });
  });

  describe('Integrations section', () => {
    it('should not render', () => {
      wrapper = createComponent();
      const views = wrapper.findAll(IntegrationView);
      const divider = findIntegrationsRule();
      const heading = findIntegrationsHeading();

      expect(divider.exists()).toBe(false);
      expect(heading.exists()).toBe(false);
      expect(views).toHaveLength(0);
    });

    it('should render', () => {
      wrapper = createComponent({ provide: { integrationViews } });
      const divider = findIntegrationsRule();
      const heading = findIntegrationsHeading();
      const views = wrapper.findAll(IntegrationView);

      expect(divider.exists()).toBe(true);
      expect(heading.exists()).toBe(true);
      expect(views).toHaveLength(integrationViews.length);
    });
  });

  it('should render ProfilePreferences properly', () => {
    wrapper = createComponent({
      provide: {
        integrationViews,
        featureFlags,
      },
    });

    expect(wrapper.element).toMatchSnapshot();
  });
});
