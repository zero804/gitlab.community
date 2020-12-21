import { shallowMount } from '@vue/test-utils';
import { GlIcon, GlSprintf, GlSkeletonLoader } from '@gitlab/ui';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import Component from '~/registry/explorer/components/list_page/image_list_row.vue';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import DeleteButton from '~/registry/explorer/components/delete_button.vue';
import {
  ROW_SCHEDULED_FOR_DELETION,
  LIST_DELETE_BUTTON_DISABLED,
  REMOVE_REPOSITORY_LABEL,
  ASYNC_DELETE_IMAGE_ERROR_MESSAGE,
  CLEANUP_TIMED_OUT_ERROR_MESSAGE,
  IMAGE_DELETE_SCHEDULED_STATUS,
  IMAGE_FAILED_DELETED_STATUS,
} from '~/registry/explorer/constants';
import { RouterLink } from '../../stubs';
import { imagesListResponse } from '../../mock_data';

describe('Image List Row', () => {
  let wrapper;
  const [item] = imagesListResponse;

  const findDetailsLink = () => wrapper.find('[data-testid="details-link"]');
  const findTagsCount = () => wrapper.find('[data-testid="tagsCount"]');
  const findDeleteBtn = () => wrapper.find(DeleteButton);
  const findClipboardButton = () => wrapper.find(ClipboardButton);
  const findWarningIcon = () => wrapper.find('[data-testid="warning-icon"]');
  const findSkeletonLoader = () => wrapper.find(GlSkeletonLoader);

  const mountComponent = props => {
    wrapper = shallowMount(Component, {
      stubs: {
        RouterLink,
        GlSprintf,
        ListItem,
      },
      propsData: {
        item,
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective(),
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('main tooltip', () => {
    it(`the title is ${ROW_SCHEDULED_FOR_DELETION}`, () => {
      mountComponent();

      const tooltip = getBinding(wrapper.element, 'gl-tooltip');
      expect(tooltip).toBeDefined();
      expect(tooltip.value.title).toBe(ROW_SCHEDULED_FOR_DELETION);
    });

    it('is disabled when item is being deleted', () => {
      mountComponent({ item: { ...item, status: IMAGE_DELETE_SCHEDULED_STATUS } });

      const tooltip = getBinding(wrapper.element, 'gl-tooltip');
      expect(tooltip.value.disabled).toBe(false);
    });
  });

  describe('image title and path', () => {
    it('contains a link to the details page', () => {
      mountComponent();

      const link = findDetailsLink();
      expect(link.html()).toContain(item.path);
      expect(link.props('to')).toMatchObject({
        name: 'details',
        params: {
          id: getIdFromGraphQLId(item.id),
        },
      });
    });

    it('contains a clipboard button', () => {
      mountComponent();
      const button = findClipboardButton();
      expect(button.exists()).toBe(true);
      expect(button.props('text')).toBe(item.location);
      expect(button.props('title')).toBe(item.location);
    });

    describe('warning icon', () => {
      it.each`
        status                         | expirationPolicyStartedAt | shown    | title
        ${IMAGE_FAILED_DELETED_STATUS} | ${true}                   | ${true}  | ${ASYNC_DELETE_IMAGE_ERROR_MESSAGE}
        ${''}                          | ${true}                   | ${true}  | ${CLEANUP_TIMED_OUT_ERROR_MESSAGE}
        ${''}                          | ${false}                  | ${false} | ${''}
      `(
        'when status is $status and expirationPolicyStartedAt is $expirationPolicyStartedAt',
        ({ expirationPolicyStartedAt, status, shown, title }) => {
          mountComponent({ item: { ...item, status, expirationPolicyStartedAt } });

          const icon = findWarningIcon();
          expect(icon.exists()).toBe(shown);

          if (shown) {
            const tooltip = getBinding(icon.element, 'gl-tooltip');
            expect(tooltip.value.title).toBe(title);
          }
        },
      );
    });
  });

  describe('delete button', () => {
    it('exists', () => {
      mountComponent();
      expect(findDeleteBtn().exists()).toBe(true);
    });

    it('has the correct props', () => {
      mountComponent();

      expect(findDeleteBtn().props()).toMatchObject({
        title: REMOVE_REPOSITORY_LABEL,
        tooltipDisabled: item.canDelete,
        tooltipTitle: LIST_DELETE_BUTTON_DISABLED,
      });
    });

    it('emits a delete event', () => {
      mountComponent();

      findDeleteBtn().vm.$emit('delete');
      expect(wrapper.emitted('delete')).toEqual([[item]]);
    });

    it.each`
      canDelete | status                           | state
      ${false}  | ${''}                            | ${true}
      ${false}  | ${IMAGE_DELETE_SCHEDULED_STATUS} | ${true}
      ${true}   | ${IMAGE_DELETE_SCHEDULED_STATUS} | ${true}
      ${true}   | ${''}                            | ${false}
    `(
      'disabled is $state when canDelete is $canDelete and status is $status',
      ({ canDelete, status, state }) => {
        mountComponent({ item: { ...item, canDelete, status } });

        expect(findDeleteBtn().props('disabled')).toBe(state);
      },
    );
  });

  describe('tags count', () => {
    it('exists', () => {
      mountComponent();
      expect(findTagsCount().exists()).toBe(true);
    });

    it('contains a tag icon', () => {
      mountComponent();
      const icon = findTagsCount().find(GlIcon);
      expect(icon.exists()).toBe(true);
      expect(icon.props('name')).toBe('tag');
    });

    describe('loading state', () => {
      it('shows a loader when metadataLoading is true', () => {
        mountComponent({ metadataLoading: true });

        expect(findSkeletonLoader().exists()).toBe(true);
      });

      it('hides the tags count while loading', () => {
        mountComponent({ metadataLoading: true });

        expect(findTagsCount().exists()).toBe(false);
      });
    });

    describe('tags count text', () => {
      it('with one tag in the image', () => {
        mountComponent({ item: { ...item, tagsCount: 1 } });

        expect(findTagsCount().text()).toMatchInterpolatedText('1 Tag');
      });
      it('with more than one tag in the image', () => {
        mountComponent({ item: { ...item, tagsCount: 3 } });

        expect(findTagsCount().text()).toMatchInterpolatedText('3 Tags');
      });
    });
  });
});
