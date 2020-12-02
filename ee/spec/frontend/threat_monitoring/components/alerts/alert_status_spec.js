import { shallowMount } from '@vue/test-utils';
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import waitForPromises from 'helpers/wait_for_promises';
import AlertStatus from 'ee/threat_monitoring/components/alerts/alert_status.vue';
import updateAlertStatusMutation from '~/alert_management/graphql/mutations/update_alert_status.mutation.graphql';
import { mockAlerts } from '../../mock_data';

const mockAlert = mockAlerts[0];

describe('AlertStatus', () => {
  let wrapper;
  const apolloMock = {
    mutate: jest.fn(),
  };

  const findStatusDropdown = () => wrapper.find(GlDropdown);
  const findFirstStatusOption = () => findStatusDropdown().find(GlDropdownItem);

  const selectFirstStatusOption = () => {
    findFirstStatusOption().vm.$emit('click');

    return waitForPromises();
  };

  function createWrapper() {
    wrapper = shallowMount(AlertStatus, {
      propsData: {
        alert: { ...mockAlert },
        projectPath: 'gitlab-org/gitlab',
      },
      mocks: {
        $apollo: apolloMock,
      },
    });
  }

  beforeEach(() => {
    createWrapper();
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  describe('a successful request', () => {
    const { iid } = mockAlert;
    const mockUpdatedMutationResult = {
      data: {
        updateAlertStatus: {
          errors: [],
          alert: {
            iid,
            status: 'RESOLVED',
          },
        },
      },
    };

    beforeEach(() => {
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(mockUpdatedMutationResult);
    });

    it('calls `$apollo.mutate` with `updateAlertStatus` mutation and variables containing `iid`, `status`, & `projectPath`', () => {
      findFirstStatusOption().vm.$emit('click');

      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
        mutation: updateAlertStatusMutation,
        variables: {
          iid,
          status: 'TRIGGERED',
          projectPath: 'gitlab-org/gitlab',
        },
      });
    });

    it('emits to the list to refetch alerts on a successful alert status change', async () => {
      expect(wrapper.emitted('alert-update')).toBeUndefined();
      await selectFirstStatusOption();
      expect(wrapper.emitted('alert-update').length).toBe(1);
    });
  });

  describe('a failed request', () => {
    beforeEach(() => {
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockReturnValue(Promise.reject(new Error()));
    });

    it('emits an error', async () => {
      await selectFirstStatusOption();

      expect(wrapper.emitted('alert-error')[0]).toEqual([
        'There was an error while updating the status of the alert. Please try again.',
      ]);
    });

    it('emits an error when triggered a second time', async () => {
      await selectFirstStatusOption();
      await wrapper.vm.$nextTick();
      await selectFirstStatusOption();
      // Should emit two errors [0,1]
      expect(wrapper.emitted('alert-error').length > 1).toBe(true);
    });

    it('reverts the status of an alert on failure', async () => {
      const status = 'Unreviewed';
      expect(findStatusDropdown().props('text')).toBe(status);
      await selectFirstStatusOption();
      await wrapper.vm.$nextTick();
      expect(findStatusDropdown().props('text')).toBe(status);
    });
  });
});
