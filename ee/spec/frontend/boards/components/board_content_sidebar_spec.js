import { GlDrawer } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import BoardContentSidebar from 'ee_component/boards/components/board_content_sidebar.vue';
import waitForPromises from 'helpers/wait_for_promises';
import BoardAssigneeDropdown from '~/boards/components/board_assignee_dropdown.vue';
import { ISSUABLE } from '~/boards/constants';
import { createStore } from '~/boards/stores';

describe('ee/BoardContentSidebar', () => {
  let wrapper;
  let store;

  const createComponent = () => {
    wrapper = mount(BoardContentSidebar, {
      provide: {
        canUpdate: true,
        rootPath: '',
      },
      store,
      stubs: {
        'board-sidebar-issue-title': '<div></div>',
        'board-sidebar-epic-select': '<div></div>',
        'board-sidebar-time-tracker': '<div></div>',
        'board-sidebar-weight-input': '<div></div>',
        'board-sidebar-labels-select': '<div></div>',
        'board-sidebar-due-date': '<div></div>',
        'board-sidebar-subscription': '<div></div>',
        'board-sidebar-milestone-select': '<div></div>',
      },
      mocks: {
        $apollo: {
          queries: {
            participants: {
              loading: false,
            },
          },
        },
      },
    });
  };

  beforeEach(() => {
    store = createStore();
    store.state.sidebarType = ISSUABLE;
    store.state.issues = { '1': { title: 'One', referencePath: 'path', assignees: [] } };
    store.state.activeId = '1';

    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('confirms we render GlDrawer', () => {
    expect(wrapper.find(GlDrawer).exists()).toBe(true);
  });

  it('applies an open attribute', () => {
    expect(wrapper.find(GlDrawer).props('open')).toBe(true);
  });

  it('renders BoardAssigneeDropdown', () => {
    expect(wrapper.find(BoardAssigneeDropdown).exists()).toBe(true);
  });

  describe('when we emit close', () => {
    it('hides GlDrawer', async () => {
      expect(wrapper.find(GlDrawer).props('open')).toBe(true);

      wrapper.find(GlDrawer).vm.$emit('close');

      await waitForPromises();

      expect(wrapper.find(GlDrawer).exists()).toBe(false);
    });
  });
});
