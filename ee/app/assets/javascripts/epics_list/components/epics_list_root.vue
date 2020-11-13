<script>
import { GlButton, GlIcon } from '@gitlab/ui';

import { s__, __, sprintf } from '~/locale';
import createFlash from '~/flash';
import Api from '~/api';
import { parsePikadayDate, dateInWords } from '~/lib/utils/datetime_utility';

import IssuableList from '~/issuable_list/components/issuable_list_root.vue';
import LabelToken from '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue';
import AuthorToken from '~/vue_shared/components/filtered_search_bar/tokens/author_token.vue';

import { IssuableListTabs, DEFAULT_PAGE_SIZE } from '~/issuable_list/constants';

import groupEpics from '../queries/group_epics.query.graphql';

import { EpicsSortOptions, FilterTokenOperators } from '../constants';

export default {
  IssuableListTabs,
  EpicsSortOptions,
  defaultPageSize: DEFAULT_PAGE_SIZE,
  epicSymbol: '&',
  components: {
    GlButton,
    GlIcon,
    IssuableList,
  },
  inject: [
    'canCreateEpic',
    'canBulkEditEpics',
    'page',
    'prev',
    'next',
    'initialState',
    'initialSortBy',
    'epicsCount',
    'epicNewPath',
    'groupFullPath',
    'groupLabelsPath',
    'emptyStatePath',
  ],
  apollo: {
    epics: {
      query: groupEpics,
      variables() {
        const queryVariables = {
          groupPath: this.groupFullPath,
          state: this.currentState,
        };

        if (this.prevPageCursor) {
          queryVariables.prevPageCursor = this.prevPageCursor;
          queryVariables.lastPageSize = this.$options.defaultPageSize;
        } else if (this.nextPageCursor) {
          queryVariables.nextPageCursor = this.nextPageCursor;
          queryVariables.firstPageSize = this.$options.defaultPageSize;
        } else {
          queryVariables.firstPageSize = this.$options.defaultPageSize;
        }

        if (this.sortedBy) {
          queryVariables.sortBy = this.sortedBy;
        }

        if (Object.keys(this.filterParams).length) {
          Object.assign(queryVariables, {
            ...this.filterParams,
          });
        }

        return queryVariables;
      },
      update(data) {
        const epicsRoot = data.group?.epics;

        return {
          list: epicsRoot?.nodes || [],
          pageInfo: epicsRoot?.pageInfo || {},
        };
      },
      error(error) {
        createFlash({
          message: s__('Epics|Something went wrong while fetching epics list.'),
          captureError: true,
          error,
        });
      },
    },
  },
  props: {
    initialFilterParams: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      currentState: this.initialState,
      currentPage: this.page,
      prevPageCursor: this.prev,
      nextPageCursor: this.next,
      filterParams: this.initialFilterParams,
      sortedBy: this.initialSortBy,
      epics: {
        list: [],
        pageInfo: {},
      },
    };
  },
  computed: {
    epicsListLoading() {
      return this.$apollo.queries.epics.loading;
    },
    epicsListEmpty() {
      return !this.$apollo.queries.epics.loading && !this.epics.list.length;
    },
    showPaginationControls() {
      const { hasPreviousPage, hasNextPage } = this.epics.pageInfo;

      // This explicit check is necessary as both the variables
      // can also be `false` and we just want to ensure that they're present.
      if (hasPreviousPage !== undefined || hasNextPage !== undefined) {
        return Boolean(hasPreviousPage || hasNextPage);
      }
      return !this.epicsListEmpty;
    },
    previousPage() {
      return Math.max(this.currentPage - 1, 0);
    },
    nextPage() {
      const nextPage = this.currentPage + 1;
      return nextPage >
        Math.ceil(this.epicsCount[this.currentState] / this.$options.defaultPageSize)
        ? null
        : nextPage;
    },
    urlParams() {
      const { search, authorUsername, labelName } = this.filterParams;
      return {
        state: this.currentState,
        page: this.currentPage,
        sort: this.sortedBy,
        prev: this.prevPageCursor || undefined,
        next: this.nextPageCursor || undefined,
        author_username: authorUsername,
        'label_name[]': labelName,
        search,
      };
    },
  },
  methods: {
    getFilteredSearchTokens() {
      return [
        {
          type: 'label_name',
          icon: 'labels',
          title: __('Label'),
          unique: false,
          symbol: '~',
          token: LabelToken,
          operators: FilterTokenOperators,
          fetchLabels: (search = '') => {
            const params = {
              only_group_labels: true,
              include_ancestor_groups: true,
              include_descendant_groups: true,
            };

            if (search) {
              params.search = search;
            }

            return Api.groupLabels(this.groupFullPath, {
              params,
            });
          },
        },
        {
          type: 'author_username',
          icon: 'user',
          title: __('Author'),
          unique: true,
          symbol: '@',
          token: AuthorToken,
          operators: FilterTokenOperators,
          fetchAuthors: (query = '') => {
            const params = {};

            if (query) {
              params.query = query;
            }

            return Api.groupMembers(this.groupFullPath, {
              params,
            });
          },
        },
      ];
    },
    getFilteredSearchValue() {
      const { authorUsername, labelName, search } = this.filterParams || {};
      const filteredSearchValue = [];

      if (authorUsername) {
        filteredSearchValue.push({
          type: 'author_username',
          value: { data: authorUsername },
        });
      }

      if (labelName?.length) {
        filteredSearchValue.push(
          ...labelName.map(label => ({
            type: 'label_name',
            value: { data: label },
          })),
        );
      }

      if (search) {
        filteredSearchValue.push(search);
      }

      return filteredSearchValue;
    },
    epicTimeframe({ startDate, dueDate }) {
      const start = startDate ? parsePikadayDate(startDate) : null;
      const due = dueDate ? parsePikadayDate(dueDate) : null;

      if (startDate && dueDate) {
        const startDateInWords = dateInWords(
          start,
          true,
          start.getFullYear() === due.getFullYear(),
        );
        const dueDateInWords = dateInWords(due, true);

        return sprintf(s__('Epics|%{startDate} – %{dueDate}'), {
          startDate: startDateInWords,
          dueDate: dueDateInWords,
        });
      } else if (startDate && !dueDate) {
        return sprintf(s__('Epics|%{startDate} – No due date'), {
          startDate: dateInWords(start, true, true),
        });
      } else if (!startDate && dueDate) {
        return sprintf(s__('Epics|No start date – %{dueDate}'), {
          dueDate: dateInWords(due, true, true),
        });
      }
      return '';
    },
    fetchIssuesBy(propsName, propValue) {
      if (propsName === 'currentPage') {
        const { startCursor, endCursor } = this.epics.pageInfo;

        if (propValue > this.currentPage) {
          this.prevPageCursor = '';
          this.nextPageCursor = endCursor;
        } else {
          this.prevPageCursor = startCursor;
          this.nextPageCursor = '';
        }
      }
      this[propsName] = propValue;
    },
    handleFilterEpics(filters = []) {
      const filterParams = {};
      const labels = [];
      const plainText = [];

      filters.forEach(filter => {
        switch (filter.type) {
          case 'author_username':
            filterParams.authorUsername = filter.value.data;
            break;
          case 'label_name':
            labels.push(filter.value.data);
            break;
          case 'filtered-search-term':
            if (filter.value.data) plainText.push(filter.value.data);
            break;
          default:
            break;
        }
      });

      if (labels.length) {
        filterParams.labelName = labels;
      }

      if (plainText.length) {
        filterParams.search = plainText.join(' ');
      }

      this.filterParams = filterParams;
    },
  },
};
</script>

<template>
  <issuable-list
    :namespace="groupFullPath"
    :tabs="$options.IssuableListTabs"
    :current-tab="currentState"
    :tab-counts="epicsCount"
    :search-input-placeholder="__('Search or filter results...')"
    :search-tokens="getFilteredSearchTokens()"
    :sort-options="$options.EpicsSortOptions"
    :initial-filter-value="getFilteredSearchValue()"
    :initial-sort-by="sortedBy"
    :issuables="epics.list"
    :issuables-loading="epicsListLoading"
    :show-pagination-controls="showPaginationControls"
    :show-discussions="true"
    :default-page-size="$options.defaultPageSize"
    :current-page="currentPage"
    :previous-page="previousPage"
    :next-page="nextPage"
    :url-params="urlParams"
    :issuable-symbol="$options.epicSymbol"
    recent-searches-storage-key="epics"
    @click-tab="fetchIssuesBy('currentState', $event)"
    @page-change="fetchIssuesBy('currentPage', $event)"
    @sort="fetchIssuesBy('sortedBy', $event)"
    @filter="handleFilterEpics"
  >
    <template v-if="canCreateEpic || canBulkEditEpics" #nav-actions>
      <gl-button v-if="canBulkEditEpics">{{ __('Edit epics') }}</gl-button>
      <gl-button v-if="canCreateEpic" category="primary" variant="success" :href="epicNewPath">{{
        __('New epic')
      }}</gl-button>
    </template>
    <template #timeframe="{ issuable }">
      <gl-icon name="calendar" />
      {{ epicTimeframe(issuable) }}
    </template>
  </issuable-list>
</template>
