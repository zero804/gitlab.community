import projectSelect from '~/project_select';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import { FILTERED_SEARCH } from '~/pages/constants';
import FilteredSearchTokenKeysIssues from 'ee/filtered_search/filtered_search_token_keys_issues';

export default () => {
  initFilteredSearch({
    page: FILTERED_SEARCH.ISSUES,
<<<<<<< HEAD
    filteredSearchTokenKeys: FilteredSearchTokenKeysIssues,
=======
>>>>>>> upstream/master
  });
  projectSelect();
};
