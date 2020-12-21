import Vuex from 'vuex';
import { createLocalVue, mount } from '@vue/test-utils';
import { within } from '@testing-library/dom';

import JiraIssueCreationVulnerabilities from '~/integrations/edit/components/jira_issue_creation_vulnerabilities.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('JiraIssuesFields', () => {
  let wrapper;

  const defaultProps = {
    hasProjectKey: true,
    initialIssueTypeId: '0',
  };

  const createComponent = props => {
    wrapper = mount(JiraIssueCreationVulnerabilities, {
      localVue,
      store: new Vuex.Store({
        state: {
          isTesting: false,
          isLoadingJiraIssueTypes: false,
          loadingJiraIssueTypesErrorMessage: '',
          jiraIssueTypes: [],
        },
      }),
      propsData: { ...defaultProps, ...props },
    });
  };

  const withinComponent = () => within(wrapper.element);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  beforeEach(() => {
    createComponent();
  });

  it('should contain a heading', () => {
    expect(
      withinComponent().findByText(/enable jira issues creation from vulnerabilities/i),
    ).not.toBe(null);
  });

  it('should contain a help text that describes the feature', () => {
    expect(
      withinComponent().findByText(
        /issues created from vulnerabilities in this project will be jira issues, even if gitLab issues are enabled/i,
      ),
    ).not.toBe(null);
  });
});
