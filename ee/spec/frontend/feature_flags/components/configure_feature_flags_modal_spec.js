import { shallowMount } from '@vue/test-utils';
import { GlModal, GlSprintf } from '@gitlab/ui';
import Component from 'ee/feature_flags/components/configure_feature_flags_modal.vue';
import Callout from '~/vue_shared/components/callout.vue';

describe('Configure Feature Flags Modal', () => {
  const mockEvent = { preventDefault: jest.fn() };
  const projectName = 'fakeProjectName';

  let wrapper;
  const factory = (props = {}, { mountFn = shallowMount, ...options } = {}) => {
    wrapper = mountFn(Component, {
      provide: {
        projectName,
      },
      stubs: { GlSprintf },
      propsData: {
        helpPath: '/help/path',
        helpClientLibrariesPath: '/help/path/#flags',
        helpClientExamplePath: '/feature-flags#clientexample',
        apiUrl: '/api/url',
        instanceId: 'instance-id-token',
        isRotating: false,
        hasRotateError: false,
        canUserRotateToken: true,
        ...props,
      },
      ...options,
    });
  };

  const findGlModal = () => wrapper.find(GlModal);
  const findPrimaryAction = () => findGlModal().props('actionPrimary');
  const findProjectNameInput = () => wrapper.find('#project_name_verification');
  const findDangerCallout = () =>
    wrapper.findAll(Callout).filter(c => c.props('category') === 'danger');

  describe('idle', () => {
    afterEach(() => wrapper.destroy());
    beforeEach(factory);

    it('should have Primary and Cancel actions', () => {
      expect(findGlModal().props('actionCancel').text).toBe('Close');
      expect(findPrimaryAction().text).toBe('Regenerate instance ID');
    });

    it('should default disable the primary action', async () => {
      const [{ disabled }] = findPrimaryAction().attributes;
      expect(disabled).toBe(true);
    });

    it('should emit a `token` event when clicking on the Primary action', async () => {
      findGlModal().vm.$emit('primary', mockEvent);
      await wrapper.vm.$nextTick();
      expect(wrapper.emitted('token')).toEqual([[]]);
      expect(mockEvent.preventDefault).toHaveBeenCalled();
    });

    it('should clear the project name input after generating the token', async () => {
      findProjectNameInput().vm.$emit('input', projectName);
      findGlModal().vm.$emit('primary', mockEvent);
      await wrapper.vm.$nextTick();
      expect(findProjectNameInput().attributes('value')).toBe('');
    });

    it('should provide an input for filling the project name', () => {
      expect(findProjectNameInput().exists()).toBe(true);
      expect(findProjectNameInput().attributes('value')).toBe('');
    });

    it('should display an help text', () => {
      const help = wrapper.find('p');
      expect(help.text()).toMatch(/More Information/);
    });

    it('should have links to the documentation', () => {
      const help = wrapper.find('p');
      const link = help.find('a[href="/help/path"]');
      expect(link.exists()).toBe(true);
      const anchoredLink = help.find('a[href="/help/path/#flags"]');
      expect(anchoredLink.exists()).toBe(true);
    });

    it('should display one and only one danger callout', () => {
      const dangerCallout = findDangerCallout();
      expect(dangerCallout.length).toBe(1);
      expect(dangerCallout.at(0).props('message')).toMatch(/Regenerating the instance ID/);
    });

    it('should display a message asking to fill the project name', () => {
      expect(wrapper.find('[data-testid="prevent-accident-text"]').text()).toMatch(projectName);
    });

    it('should display the api URL in an input box', () => {
      const input = wrapper.find('#api_url');
      expect(input.element.value).toBe('/api/url');
    });

    it('should display the instance ID in an input box', () => {
      const input = wrapper.find('#instance_id');
      expect(input.element.value).toBe('instance-id-token');
    });
  });

  describe('verified', () => {
    afterEach(() => wrapper.destroy());
    beforeEach(factory);

    it('should enable the primary action', async () => {
      findProjectNameInput().vm.$emit('input', projectName);
      await wrapper.vm.$nextTick();
      const [{ disabled }] = findPrimaryAction().attributes;
      expect(disabled).toBe(false);
    });
  });

  describe('cannot rotate token', () => {
    afterEach(() => wrapper.destroy());
    beforeEach(factory.bind(null, { canUserRotateToken: false }));

    it('should not display the primary action', async () => {
      expect(findPrimaryAction()).toBe(null);
    });

    it('shold not display regenerating instance ID', async () => {
      expect(findDangerCallout().exists()).toBe(false);
    });

    it('should disable the project name input', async () => {
      expect(findProjectNameInput().exists()).toBe(false);
    });
  });

  describe('has rotate error', () => {
    afterEach(() => wrapper.destroy());
    beforeEach(factory.bind(null, { hasRotateError: false }));

    it('should display an error', async () => {
      expect(wrapper.find('.text-danger')).toExist();
      expect(wrapper.find('[name="warning"]')).toExist();
    });
  });

  describe('is rotating', () => {
    afterEach(() => wrapper.destroy());
    beforeEach(factory.bind(null, { isRotating: true }));

    it('should disable the project name input', async () => {
      expect(findProjectNameInput().attributes('disabled')).toBeTruthy();
    });
  });
});