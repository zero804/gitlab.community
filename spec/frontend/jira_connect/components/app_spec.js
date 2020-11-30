import { shallowMount } from '@vue/test-utils';
import { GlAlert } from '@gitlab/ui';
import JiraConnectApp from '~/jira_connect/components/app.vue';
import createStore from '~/jira_connect/store';

describe('Jira Connect App', () => {
  let wrapper;
  let mockStore;

  const findAlert = () => wrapper.find(GlAlert);

  function createComponent() {
    mockStore = createStore();
    // create a dummy parent component, allowing us to mock $root.$data and our global store
    const Parent = {
      data() {
        return {
          state: mockStore.state,
        };
      },
    };

    wrapper = shallowMount(JiraConnectApp, {
      parentComponent: Parent,
    });
  }

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('with error message', () => {
    const testErrorMessage = 'Test error';

    beforeEach(() => {
      createComponent();
      mockStore.setErrorMessage(testErrorMessage);
    });

    it('renders GlAlert with error message', () => {
      expect(findAlert().isVisible()).toBe(true);
      expect(findAlert().html()).toContain(testErrorMessage);
    });
  });
});
