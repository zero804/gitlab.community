import Vue from 'vue';
import createFlash from '~/flash';
import ProfilePreferences from './components/profile_preferences.vue';
import { parseDataset } from './utils';

export default () => {
  const el = document.querySelector('#js-profile-preferences-app');

  let provide;
  try {
    provide = parseDataset(el.dataset);
  } catch (error) {
    createFlash({
      message: error.message,
      captureError: true,
      error,
    });

    return undefined;
  }

  return new Vue({
    el,
    name: 'ProfilePreferencesApp',
    provide,
    render: createElement => createElement(ProfilePreferences),
  });
};
