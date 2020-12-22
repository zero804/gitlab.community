import axios from 'axios';
import { refreshCurrentPage } from '~/lib/utils/url_utility';
import * as types from './mutation_types';

export const setOverride = ({ commit }, override) => commit(types.SET_OVERRIDE, override);
export const setIsSaving = ({ commit }, isSaving) => commit(types.SET_IS_SAVING, isSaving);
export const setIsTesting = ({ commit }, isTesting) => commit(types.SET_IS_TESTING, isTesting);
export const setIsResetting = ({ commit }, isResetting) =>
  commit(types.SET_IS_RESETTING, isResetting);

export const requestResetIntegration = ({ commit }) => {
  commit(types.REQUEST_RESET_INTEGRATION);
};
export const receiveResetIntegrationSuccess = () => {
  refreshCurrentPage();
};
export const receiveResetIntegrationError = ({ commit }) => {
  commit(types.RECEIVE_RESET_INTEGRATION_ERROR);
};

export const fetchResetIntegration = ({ dispatch, getters }) => {
  dispatch('requestResetIntegration');

  return axios
    .post(getters.propsSource.resetPath, { params: { format: 'json' } })
    .then(() => dispatch('receiveResetIntegrationSuccess'))
    .catch(() => dispatch('receiveResetIntegrationError'));
};

export const setIsLoadingJiraIssueTypes = ({ commit }, isLoadingJiraIssueTypes) => {
  commit(types.SET_IS_LOADING_JIRA_ISSUE_TYPES, isLoadingJiraIssueTypes);
};
export const receivedJiraIssueTypesSuccess = ({ commit }, issueTypes) => {
  commit(types.SET_LOADING_JIRA_ISSUE_TYPES_ERROR_MESSAGE, '');
  commit(types.SET_JIRA_ISSUE_TYPES, issueTypes);
};

export const setLoadingJiraIssueTypesErrorMessage = ({ commit }, errorMessage) => {
  commit(types.SET_LOADING_JIRA_ISSUE_TYPES_ERROR_MESSAGE, errorMessage);
};
