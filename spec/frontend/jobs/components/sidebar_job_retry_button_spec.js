import { GlButton, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import job from '../mock_data';
import SidebarJobRetryButton from '~/jobs/components/sidebar_job_retry_button.vue';
import createStore from '~/jobs/store';

describe('Job Retry Button', () => {
  let store;
  let wrapper;

  const forwardDeploymentFailure = 'forward_deployment_failure';
  const findRetryButton = () => wrapper.find(GlButton);
  const findRetryLink = () => wrapper.find(GlLink);

  const createWrapper = ({ props = {} } = {}) => {
    store = createStore();
    wrapper = shallowMount(SidebarJobRetryButton, {
      propsData: {
        href: job.retry_path,
        modalId: 'modal-id',
        ...props,
      },
      store,
    });
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  beforeEach(createWrapper);

  it.each([
    [null, false, true],
    ['unmet_prerequisites', false, true],
    [forwardDeploymentFailure, true, false],
  ])(
    'when error is: %s is, should render button: %s | should render link: %s',
    async (failureReason, buttonExists, linkExists) => {
      await store.dispatch('receiveJobSuccess', {
        ...job,
        failure_reason: failureReason,
      });
      expect(findRetryButton().exists()).toBe(buttonExists);
      expect(findRetryLink().exists()).toBe(linkExists);
      expect(wrapper.text()).toMatch('Retry');
    },
  );

  describe('Button', () => {
    it('should have the correct configuration', async () => {
      await store.dispatch('receiveJobSuccess', { failure_reason: forwardDeploymentFailure });

      expect(findRetryButton().attributes('category')).toBe('primary');
      expect(findRetryButton().attributes('variant')).toBe('info');
    });
  });

  describe('Link', () => {
    it('should have the correct configuration', () => {
      expect(findRetryLink().attributes('data-method')).toBe('post');
      expect(findRetryLink().attributes('href')).toBe(job.retry_path);
    });
  });
});
