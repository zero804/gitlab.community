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

  const findLocalizationAnchor = () => wrapper.find('#localization');

  const findUserLanguageOptionList = () =>
    wrapper.findAll('[data-testid="user-preferred-language-option"]');

  const findUserLanguageSelectedOption = () =>
    wrapper.find('[data-testid="user-preferred-language-option"]:checked');

  const findUserFirstDayOfWeekOptionList = () =>
    wrapper.findAll('[data-testid="user-first-day-of-week-option"]');

  const findUserFirstDayOfWeekSelectedOption = () =>
    wrapper.find('[data-testid="user-first-day-of-week-option"]:checked');

  const findUserTimeSettingsRule = () => wrapper.find('[data-testid="user-time-settings-rule"]');

  const findUserTimeSettingsHeading = () =>
    wrapper.find('[data-testid="user-time-settings-heading"]');

  const findUserTimeFormatOption = () => wrapper.find('[data-testid="user-time-format-option"]');

  const findUserTimeRelativeOption = () =>
    wrapper.find('[data-testid="user-time-relative-option"]');

  const findIntegrationsRule = () =>
    wrapper.find('[data-testid="profile-preferences-integrations-rule"]');

  const findIntegrationsHeading = () =>
    wrapper.find('[data-testid="profile-preferences-integrations-heading"]');

  const findIntegrationViewList = () => wrapper.findAll(IntegrationView);

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
      expect(findUserTimeSettingsRule().exists()).toBe(true);
      expect(findUserTimeSettingsHeading().exists()).toBe(true);
      expect(findUserTimeFormatOption().exists()).toBe(true);
      expect(findUserTimeRelativeOption().exists()).toBe(true);
    });

    it('allows the user to toggle their time format preference', async () => {
      const userTimeFormatOption = findUserTimeFormatOption();
      expect(userTimeFormatOption.element.checked).toBe(false);
      await userTimeFormatOption.trigger('click');
      expect(userTimeFormatOption.element.checked).toBe(true);
    });

    it('allows the user to toggle their time display preference', async () => {
      const userTimeTimeRelativeOption = findUserTimeRelativeOption();
      expect(userTimeTimeRelativeOption.element.checked).toBe(false);
      await userTimeTimeRelativeOption.trigger('click');
      expect(userTimeTimeRelativeOption.element.checked).toBe(true);
    });
  });

  describe('with `userTimeSettings` feature flag disabled', () => {
    it('should not render user time settings', () => {
      wrapper = createComponent();
      expect(findUserTimeSettingsRule().exists()).toBe(false);
      expect(findUserTimeSettingsHeading().exists()).toBe(false);
      expect(findUserTimeFormatOption().exists()).toBe(false);
      expect(findUserTimeRelativeOption().exists()).toBe(false);
    });
  });

  describe('Integrations section', () => {
    it('should not render', () => {
      wrapper = createComponent();

      expect(findIntegrationsRule().exists()).toBe(false);
      expect(findIntegrationsHeading().exists()).toBe(false);
      expect(findIntegrationViewList()).toHaveLength(0);
    });

    it('should render', () => {
      wrapper = createComponent({ provide: { integrationViews } });

      expect(findIntegrationsRule().exists()).toBe(true);
      expect(findIntegrationsHeading().exists()).toBe(true);
      expect(findIntegrationViewList()).toHaveLength(integrationViews.length);
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
