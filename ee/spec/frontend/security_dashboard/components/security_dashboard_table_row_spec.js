import { GlFormCheckbox } from '@gitlab/ui';
import { mount, shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import SecurityDashboardTableRow from 'ee/security_dashboard/components/security_dashboard_table_row.vue';
import { VULNERABILITY_MODAL_ID } from 'ee/vue_shared/security_reports/components/constants';
import createStore from 'ee/security_dashboard/store';
import { DASHBOARD_TYPES } from 'ee/security_dashboard/store/constants';
import { trimText } from 'helpers/text_helper';
import mockDataVulnerabilities from '../store/modules/vulnerabilities/data/mock_data_vulnerabilities';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Security Dashboard Table Row', () => {
  let wrapper;
  let store;

  const createComponent = (mountFunc, { props = {} } = {}) => {
    wrapper = mountFunc(SecurityDashboardTableRow, {
      localVue,
      store,
      propsData: {
        ...props,
      },
    });
  };

  beforeEach(() => {
    store = createStore();
    jest.spyOn(store, 'dispatch');
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findLoader = () => wrapper.find('.js-skeleton-loader');
  const findContent = i => wrapper.findAll('.table-mobile-content').at(i);
  const findAllIssueCreated = () => wrapper.findAll('[data-testid="issues-icon"]');
  const hasSelectedClass = () => wrapper.classes('gl-bg-blue-50');
  const findCheckbox = () => wrapper.find(GlFormCheckbox);

  describe('when loading', () => {
    beforeEach(() => {
      createComponent(shallowMount, { props: { isLoading: true } });
    });

    it('should display the skeleton loader', () => {
      expect(findLoader().exists()).toBeTruthy();
    });

    it('should render a ` ` for severity', () => {
      expect(wrapper.vm.severity).toEqual(' ');
      expect(findContent(0).text()).toEqual('');
    });

    it('should render a `` for the report type and scanner', () => {
      expect(findContent(3).text()).toEqual('');
      expect(wrapper.find('vulnerability-vendor').exists()).toBeFalsy();
    });

    it('should not render action buttons', () => {
      expect(wrapper.findAll('.action-buttons button')).toHaveLength(0);
    });
  });

  describe('when loaded', () => {
    let vulnerability = mockDataVulnerabilities[0];

    beforeEach(() => {
      createComponent(mount, { props: { vulnerability } });
    });

    it('should not display the skeleton loader', () => {
      expect(findLoader().exists()).toBeFalsy();
    });

    it('should render the severity', () => {
      expect(
        findContent(0)
          .text()
          .toLowerCase(),
      ).toContain(vulnerability.severity);
    });

    it('should render the identifier cell', () => {
      const { identifiers } = vulnerability;
      expect(findContent(2).text()).toContain(identifiers[0].name);
      expect(trimText(findContent(2).text())).toContain(`${identifiers.length - 1} more`);
    });

    it('should render the report type', () => {
      expect(
        findContent(3)
          .text()
          .toLowerCase(),
      ).toContain(vulnerability.report_type.toLowerCase());
    });

    it('should render the scanner vendor if the scanner does exist', () => {
      expect(findContent(3).text()).toContain(vulnerability.scanner.vendor);
    });

    describe('the project name', () => {
      it('should render the name', () => {
        expect(findContent(1).text()).toContain(vulnerability.name);
      });

      it('should render the project namespace', () => {
        expect(findContent(1).text()).toContain(vulnerability.location.file);
      });

      it('should fire the setModalData action and open the modal when clicked', () => {
        jest.spyOn(store, 'dispatch').mockImplementation();
        jest.spyOn(wrapper.vm.$root, '$emit');

        const el = wrapper.find({ ref: 'vulnerability-title' });
        el.trigger('click');

        expect(store.dispatch).toHaveBeenCalledWith('vulnerabilities/setModalData', {
          vulnerability,
        });
        expect(wrapper.vm.$root.$emit).toHaveBeenCalledWith(
          'bv::show::modal',
          VULNERABILITY_MODAL_ID,
        );
      });
    });

    describe('Group Security Dashboard', () => {
      beforeEach(() => {
        store.state.dashboardType = DASHBOARD_TYPES.GROUP;

        createComponent(shallowMount, {
          props: { vulnerability },
        });
      });

      it('should contain project name as the namespace', () => {
        expect(findContent(1).text()).toContain(vulnerability.project.full_name);
      });
    });

    describe('Non-group Security Dashboard', () => {
      beforeEach(() => {
        // eslint-disable-next-line prefer-destructuring
        vulnerability = mockDataVulnerabilities[7];

        createComponent(shallowMount, { props: { vulnerability } });
      });

      it('should contain container image as the namespace', () => {
        expect(findContent(1).text()).toContain(vulnerability.location.image);
      });
    });
  });

  describe('with a dismissed vulnerability', () => {
    const vulnerability = mockDataVulnerabilities[2];

    beforeEach(() => {
      createComponent(shallowMount, { props: { vulnerability } });
    });

    it('should have a `dismissed` class', () => {
      expect(wrapper.classes()).toContain('dismissed');
    });

    it('should render a `DISMISSED` tag', () => {
      expect(wrapper.text()).toContain('dismissed');
    });
  });

  describe('with valid issue feedback', () => {
    const vulnerability = mockDataVulnerabilities[3];

    beforeEach(() => {
      createComponent(mount, { props: { vulnerability } });
    });

    it('should have a `issues` icon', () => {
      expect(findAllIssueCreated()).toHaveLength(1);
    });
  });

  describe('with invalid issue feedback', () => {
    const vulnerability = mockDataVulnerabilities[6];

    beforeEach(() => {
      createComponent(mount, { props: { vulnerability } });
    });

    it('should not have a `issues` icon', () => {
      expect(findAllIssueCreated()).toHaveLength(0);
    });
  });

  describe('with no issue feedback', () => {
    const vulnerability = mockDataVulnerabilities[0];

    beforeEach(() => {
      createComponent(shallowMount, { props: { vulnerability } });
    });

    it('should not have a `issues` icon', () => {
      expect(findAllIssueCreated()).toHaveLength(0);
    });

    it('should be unselected', () => {
      expect(hasSelectedClass()).toBe(false);
      expect(findCheckbox().attributes('checked')).toBeFalsy();
    });

    describe('when checked', () => {
      beforeEach(() => {
        findCheckbox().vm.$emit('change');
      });

      it('should be selected', () => {
        expect(hasSelectedClass()).toBe(true);
        expect(findCheckbox().attributes('checked')).toBe('true');
      });

      it('should update store', () => {
        expect(store.dispatch).toHaveBeenCalledWith(
          'vulnerabilities/selectVulnerability',
          vulnerability,
        );
      });

      describe('when unchecked', () => {
        beforeEach(() => {
          findCheckbox().vm.$emit('change');
        });

        it('should be unselected', () => {
          expect(hasSelectedClass()).toBe(false);
          expect(findCheckbox().attributes('checked')).toBeFalsy();
        });

        it('should update store', () => {
          expect(store.dispatch).toHaveBeenCalledWith(
            'vulnerabilities/deselectVulnerability',
            vulnerability,
          );
        });
      });
    });
  });

  describe('with less than two identifiers', () => {
    const vulnerability = mockDataVulnerabilities[1];

    beforeEach(() => {
      createComponent(shallowMount, { props: { vulnerability } });
    });

    it('should render the identifier cell', () => {
      const { identifiers } = vulnerability;
      expect(findContent(2).text()).toBe(identifiers[0].name);
    });
  });
});
