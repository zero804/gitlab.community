import { mount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { GlDropdown, GlDropdownItem, GlSearchBoxByType, GlLoadingIcon } from '@gitlab/ui';
import httpStatus from '~/lib/utils/http_status';
import { featureAccessLevel } from '~/pages/projects/shared/permissions/constants';
import { ListType } from '~/boards/constants';
import Api from '~/api';
import eventHub from '~/boards/eventhub';
import { deprecatedCreateFlash as flash } from '~/flash';

import ProjectSelect from '~/boards/components/project_select.vue';

import { listObj, mockRawGroupProjects } from './mock_data';

jest.mock('~/boards/eventhub');
jest.mock('~/flash');

const dummyGon = {
  api_version: 'v4',
  relative_url_root: '/gitlab',
};

const mockGroupId = 1;
const mockProjectsList1 = mockRawGroupProjects.slice(0, 1);
const mockProjectsList2 = mockRawGroupProjects.slice(1);

describe('ProjectSelect component', () => {
  let wrapper;
  let mock;

  const findGlDropdown = () => wrapper.find(GlDropdown);
  const findGlSearchBoxByType = () => wrapper.find(GlSearchBoxByType);
  const findGlDropdownItems = () => wrapper.findAll(GlDropdownItem);
  const findFirstGlDropdownItem = () => findGlDropdownItems().at(0);
  const findGlLoadingIcon = () => wrapper.find(GlLoadingIcon);
  const findEmptySearchMessage = () => wrapper.find("[data-testid='empty-result-message']");

  const mockGetRequest = (data = [], statusCode = httpStatus.OK) => {
    mock.onGet(`/gitlab/api/v4/groups/${mockGroupId}/projects.json`).replyOnce(statusCode, data);
  };

  const createWrapper = async ({
    list = listObj,
    mockInitialFetch = [],
    mockMethods = {},
  } = {}) => {
    mockGetRequest(mockInitialFetch);

    wrapper = mount(ProjectSelect, {
      propsData: {
        list,
      },
      provide: {
        groupId: 1,
      },
      methods: {
        ...mockMethods,
      },
    });

    await axios.waitForAll();
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    window.gon = dummyGon;
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    jest.clearAllMocks();
  });

  describe('mounted', () => {
    it('calls fetchProjects method and sets initialLoading on and off', async () => {
      const fetchProjectSpy = jest.fn();

      mockGetRequest();

      wrapper = mount(ProjectSelect, {
        propsData: {
          list: listObj,
        },
        provide: {
          groupId: 1,
        },
        methods: {
          fetchProjects: fetchProjectSpy,
        },
      });

      expect(wrapper.vm.initialLoading).toBe(true);
      expect(fetchProjectSpy).toHaveBeenCalledTimes(1);

      await axios.waitForAll();

      expect(wrapper.vm.initialLoading).toBe(false);
    });
  });

  describe('computed', () => {
    describe('fetchOptions', () => {
      describe("when list type is defined and isn't backlog", () => {
        it('returns an additional fetch option (min_access_level)', async () => {
          await createWrapper({ list: { ...listObj, type: ListType.label } });

          expect(wrapper.vm.fetchOptions).toEqual({
            ...wrapper.vm.$options.defaultFetchOptions,
            min_access_level: featureAccessLevel.EVERYONE,
          });
        });
      });

      describe("when list type isn't defined", () => {
        it('returns only the default fetch options', async () => {
          await createWrapper();

          expect(wrapper.vm.fetchOptions).toEqual(wrapper.vm.$options.defaultFetchOptions);
        });
      });
    });

    describe('isFetchResultEmpty', () => {
      it('returns true when this.project is empty', async () => {
        await createWrapper();

        expect(wrapper.vm.isFetchResultEmpty).toBe(true);
      });

      it('returns false when this.project is not empty', async () => {
        await createWrapper({ mockInitialFetch: mockProjectsList1 });

        expect(wrapper.vm.isFetchResultEmpty).toBe(false);
      });
    });
  });

  describe('methods', () => {
    describe('fetchProjects', () => {
      it('flashes an error message when fetching fails', async () => {
        await createWrapper();
        mockGetRequest([], httpStatus.INTERNAL_SERVER_ERROR);

        wrapper.vm.fetchProjects();

        await axios.waitForAll();

        expect(flash).toHaveBeenCalledTimes(1);
        expect(flash).toHaveBeenCalledWith('Something went wrong while fetching projects');
      });
    });
  });

  describe('template', () => {
    beforeEach(async () => {
      await createWrapper({ mockInitialFetch: mockProjectsList1 });
    });

    it('GlDropdown is rendered with default text', () => {
      const defaultText = 'Select a project';

      expect(findGlDropdown().exists()).toBe(true);
      expect(findGlDropdown().text()).toContain(defaultText);
    });

    it('GlSearchBoxByType is rendered and has debounce attribute set to 250', () => {
      expect(findGlSearchBoxByType().exists()).toBe(true);
      expect(findGlSearchBoxByType().vm.inputAttributes).toMatchObject({
        placeholder: 'Search projects',
        debounce: '250',
      });
    });

    it("GlDropdownItem is renders with the fetched project's name", () => {
      expect(findFirstGlDropdownItem().exists()).toBe(true);
      expect(findFirstGlDropdownItem().text()).toContain(mockProjectsList1[0].name);
    });

    it('GlLoadingIcon is not rendered by default', () => {
      expect(findGlLoadingIcon().isVisible()).toBe(false);
    });

    it('renders the empty search result message', async () => {
      await createWrapper();

      expect(findEmptySearchMessage().isVisible()).toBe(true);
    });
  });

  describe('behaviors', () => {
    describe('when no project is selected', () => {
      beforeEach(async () => {
        await createWrapper({ mockInitialFetch: mockProjectsList1 });
      });

      it('returns and renders the default text when no project is selected', async () => {
        const defaultText = 'Select a project';

        expect(wrapper.vm.selectedProjectName).toBe(defaultText);
        expect(findGlDropdown().text()).toContain(defaultText);
      });
    });

    describe('when a project is selected', () => {
      let selectProjectSpy;

      beforeEach(async () => {
        await createWrapper({ mockInitialFetch: mockProjectsList1 });

        selectProjectSpy = jest.spyOn(wrapper.vm, 'selectProject');

        await findFirstGlDropdownItem()
          .find('button')
          .trigger('click');
      });

      it('selectProject method sets selectedProject and emits setSelectedProject when called', () => {
        const {
          id,
          path_with_namespace: path,
          name,
          name_with_namespace: namespacedName,
        } = mockProjectsList1[0];

        expect(selectProjectSpy).toHaveBeenCalledTimes(1);
        expect(wrapper.vm.projects[0]).toMatchObject({
          id,
          path,
          name,
          namespacedName,
        });
        expect(wrapper.vm.selectedProject).toEqual(wrapper.vm.projects[0]);

        expect(eventHub.$emit).toHaveBeenCalledWith('setSelectedProject', wrapper.vm.projects[0]);
      });

      it('selectedProjectName returns the name of the selected project', () => {
        expect(wrapper.vm.selectedProjectName).toBe(mockProjectsList1[0].name);
      });

      it('GlDropdown renders the name of the selected project', () => {
        expect(findGlDropdown().text()).toContain(mockProjectsList1[0].name);
      });
    });
  });

  describe('search', () => {
    describe('when search term is entered', () => {
      it('set searchTerm and calls fetchProjects method', async () => {
        const fetchProjectSpy = jest.fn();

        await createWrapper({
          mockInitialFetch: mockProjectsList1,
          mockMethods: {
            fetchProjects: fetchProjectSpy,
          },
        });

        fetchProjectSpy.mockClear();

        findGlSearchBoxByType().vm.$emit('input', 'foobar');

        expect(wrapper.vm.searchTerm).toBe('foobar');
        expect(fetchProjectSpy).toHaveBeenCalledTimes(1);
      });

      it('displays the retrieved list of projects', async () => {
        await createWrapper({ mockInitialFetch: mockProjectsList1 });

        mockGetRequest(mockProjectsList2);
        jest.spyOn(Api, 'groupProjects');

        findGlSearchBoxByType().vm.$emit('input', 'foobar');

        await axios.waitForAll();

        expect(Api.groupProjects).toHaveBeenCalledTimes(1);
        expect(Api.groupProjects).toHaveBeenCalledWith(
          mockGroupId,
          'foobar',
          wrapper.vm.fetchOptions,
        );

        expect(findFirstGlDropdownItem().text()).toContain(mockProjectsList2[0].name);
      });

      it('displays and hides gl-loading-icon while and after fetching', async () => {
        await createWrapper({ mockInitialFetch: mockProjectsList1 });

        mockGetRequest(mockProjectsList2);

        findGlSearchBoxByType().vm.$emit('input', 'foobar');

        await wrapper.vm.$nextTick();

        expect(findGlLoadingIcon().isVisible()).toBe(true);

        await axios.waitForAll();

        expect(findGlLoadingIcon().isVisible()).toBe(false);
      });
    });
  });
});
