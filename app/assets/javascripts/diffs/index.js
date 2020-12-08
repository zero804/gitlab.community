import Vue from 'vue';
import { mapActions, mapState, mapGetters } from 'vuex';
import Cookies from 'js-cookie';
import { parseBoolean } from '~/lib/utils/common_utils';
import FindFile from '~/vue_shared/components/file_finder/index.vue';
import eventHub from '../notes/event_hub';
import diffsApp from './components/app.vue';
import { TREE_LIST_STORAGE_KEY, DIFF_WHITESPACE_COOKIE_NAME } from './constants';

export default function initDiffsApp(store) {
  const fileFinderEl = document.getElementById('js-diff-file-finder');

  if (fileFinderEl) {
    // eslint-disable-next-line no-new
    new Vue({
      el: fileFinderEl,
      store,
      computed: {
        ...mapState('diffs', ['fileFinderVisible', 'isLoading']),
        ...mapGetters('diffs', ['flatBlobsList']),
      },
      watch: {
        fileFinderVisible(newVal, oldVal) {
          if (newVal && !oldVal && !this.flatBlobsList.length) {
            eventHub.$emit('fetchDiffData');
          }
        },
      },
      methods: {
        ...mapActions('diffs', ['toggleFileFinder', 'scrollToFile']),
        openFile(file) {
          window.mrTabs.tabShown('diffs');
          this.scrollToFile(file.path);
        },
      },
      render(createElement) {
        return createElement(FindFile, {
          props: {
            files: this.flatBlobsList,
            visible: this.fileFinderVisible,
            loading: this.isLoading,
            showDiffStats: true,
            clearSearchOnClose: false,
          },
          on: {
            toggle: this.toggleFileFinder,
            click: this.openFile,
          },
          class: ['diff-file-finder'],
          style: {
            display: this.fileFinderVisible ? '' : 'none',
          },
        });
      },
    });
  }

  return new Vue({
    el: '#js-diffs-app',
    name: 'MergeRequestDiffs',
    components: {
      diffsApp,
    },
    store,
    data() {
      const { dataset } = document.querySelector(this.$options.el);

      return {
        endpoint: dataset.endpoint,
        endpointMetadata: dataset.endpointMetadata || '',
        endpointBatch: dataset.endpointBatch || '',
        endpointCoverage: dataset.endpointCoverage || '',
        projectPath: dataset.projectPath,
        helpPagePath: dataset.helpPagePath,
        currentUser: JSON.parse(dataset.currentUserData) || {},
        changesEmptyStateIllustration: dataset.changesEmptyStateIllustration,
        isFluidLayout: parseBoolean(dataset.isFluidLayout),
        dismissEndpoint: dataset.dismissEndpoint,
        showSuggestPopover: parseBoolean(dataset.showSuggestPopover),
        showWhitespaceDefault: parseBoolean(dataset.showWhitespaceDefault),
        viewDiffsFileByFile: parseBoolean(dataset.fileByFileDefault),
        defaultSuggestionCommitMessage: dataset.defaultSuggestionCommitMessage,
      };
    },
    computed: {
      ...mapState({
        activeTab: state => state.page.activeTab,
      }),
    },
    created() {
      const treeListStored = localStorage.getItem(TREE_LIST_STORAGE_KEY);
      const renderTreeList = treeListStored !== null ? parseBoolean(treeListStored) : true;

      this.setRenderTreeList(renderTreeList);

      // Set whitespace default as per user preferences unless cookie is already set
      if (!Cookies.get(DIFF_WHITESPACE_COOKIE_NAME)) {
        const hideWhitespace = this.showWhitespaceDefault ? '0' : '1';
        this.setShowWhitespace({ showWhitespace: hideWhitespace !== '1' });
      }
    },
    methods: {
      ...mapActions('diffs', ['setRenderTreeList', 'setShowWhitespace']),
    },
    render(createElement) {
      return createElement('diffs-app', {
        props: {
          endpoint: this.endpoint,
          endpointMetadata: this.endpointMetadata,
          endpointBatch: this.endpointBatch,
          endpointCoverage: this.endpointCoverage,
          currentUser: this.currentUser,
          projectPath: this.projectPath,
          helpPagePath: this.helpPagePath,
          shouldShow: this.activeTab === 'diffs',
          changesEmptyStateIllustration: this.changesEmptyStateIllustration,
          isFluidLayout: this.isFluidLayout,
          dismissEndpoint: this.dismissEndpoint,
          showSuggestPopover: this.showSuggestPopover,
          fileByFileUserPreference: this.viewDiffsFileByFile,
          defaultSuggestionCommitMessage: this.defaultSuggestionCommitMessage,
        },
      });
    },
  });
}
