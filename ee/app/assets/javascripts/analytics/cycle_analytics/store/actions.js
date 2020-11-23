import Api from 'ee/api';
import { deprecatedCreateFlash as createFlash } from '~/flash';
import { __ } from '~/locale';
import httpStatus from '~/lib/utils/http_status';
import * as types from './mutation_types';
import { FETCH_VALUE_STREAM_DATA } from '../constants';
import { removeFlash, throwIfUserForbidden } from '../utils';

const appendExtension = path => (path.indexOf('.') > -1 ? path : `${path}.json`);

export const setPaths = ({ dispatch }, options) => {
  const { groupPath, milestonesPath = '', labelsPath = '' } = options;

  return dispatch('filters/setEndpoints', {
    labelsEndpoint: appendExtension(labelsPath),
    milestonesEndpoint: appendExtension(milestonesPath),
    groupEndpoint: groupPath,
  });
};

export const setFeatureFlags = ({ commit }, featureFlags) =>
  commit(types.SET_FEATURE_FLAGS, featureFlags);

export const setSelectedProjects = ({ commit }, projects) =>
  commit(types.SET_SELECTED_PROJECTS, projects);

export const setDateRange = ({ commit, dispatch }, { skipFetch = false, startDate, endDate }) => {
  commit(types.SET_DATE_RANGE, { startDate, endDate });

  if (skipFetch) return false;

  return dispatch('fetchCycleAnalyticsData');
};

export const requestCycleAnalyticsData = ({ commit }) => commit(types.REQUEST_CYCLE_ANALYTICS_DATA);

export const receiveCycleAnalyticsDataSuccess = ({ commit, dispatch }) => {
  commit(types.RECEIVE_CYCLE_ANALYTICS_DATA_SUCCESS);
  dispatch('typeOfWork/fetchTopRankedGroupLabels');
};

export const receiveCycleAnalyticsDataError = ({ commit }, { response = {} }) => {
  const { status = httpStatus.INTERNAL_SERVER_ERROR } = response;

  commit(types.RECEIVE_CYCLE_ANALYTICS_DATA_ERROR, status);
  if (status !== httpStatus.FORBIDDEN) {
    createFlash(__('There was an error while fetching value stream analytics data.'));
  }
};

export const fetchCycleAnalyticsData = ({ dispatch }) => {
  removeFlash();

  return Promise.resolve()
    .then(() => dispatch('requestCycleAnalyticsData'))
    .then(() => dispatch('fetchValueStreams'))
    .then(() => dispatch('receiveCycleAnalyticsDataSuccess'))
    .catch(error => {
      return Promise.all([
        dispatch('receiveCycleAnalyticsDataError', error),
        dispatch('durationChart/setLoading', false),
        dispatch('typeOfWork/setLoading', false),
      ]);
    });
};

export const requestGroupStages = ({ commit }) => commit(types.REQUEST_GROUP_STAGES);

export const receiveGroupStagesError = ({ commit }, error) => {
  commit(types.RECEIVE_GROUP_STAGES_ERROR, error);
  createFlash(__('There was an error fetching value stream analytics stages.'));
};

export const receiveGroupStagesSuccess = ({ commit, dispatch }, stages) => {
  commit(types.RECEIVE_GROUP_STAGES_SUCCESS, stages);
  return dispatch('stages/setDefaultSelectedStage');
};

export const fetchGroupStagesAndEvents = ({ dispatch, getters }) => {
  const {
    currentValueStreamId: valueStreamId,
    currentGroupPath: groupId,
    cycleAnalyticsRequestParams: { created_after, project_ids },
  } = getters;

  dispatch('requestGroupStages');
  dispatch('customStages/setStageEvents', []);

  return Api.cycleAnalyticsGroupStagesAndEvents({
    groupId,
    valueStreamId,
    params: {
      start_date: created_after,
      project_ids,
    },
  })
    .then(({ data: { stages = [], events = [] } }) => {
      dispatch('receiveGroupStagesSuccess', stages);
      dispatch('customStages/setStageEvents', events);
    })
    .catch(error => {
      throwIfUserForbidden(error);
      return dispatch('receiveGroupStagesError', error);
    });
};

export const initializeCycleAnalyticsSuccess = ({ commit }) =>
  commit(types.INITIALIZE_CYCLE_ANALYTICS_SUCCESS);

export const initializeCycleAnalytics = ({ dispatch, commit }, initialData = {}) => {
  commit(types.INITIALIZE_CYCLE_ANALYTICS, initialData);

  const {
    featureFlags = {},
    milestonesPath,
    labelsPath,
    selectedAuthor,
    selectedMilestone,
    selectedAssigneeList,
    selectedLabelList,
    group,
  } = initialData;
  commit(types.SET_FEATURE_FLAGS, featureFlags);

  if (group?.fullPath) {
    return Promise.all([
      dispatch('setPaths', { groupPath: group.fullPath, milestonesPath, labelsPath }),
      dispatch('filters/initialize', {
        selectedAuthor,
        selectedMilestone,
        selectedAssigneeList,
        selectedLabelList,
      }),
      dispatch('durationChart/setLoading', true),
      dispatch('typeOfWork/setLoading', true),
    ])
      .then(() => dispatch('fetchCycleAnalyticsData'))
      .then(() => dispatch('initializeCycleAnalyticsSuccess'));
  }

  return dispatch('initializeCycleAnalyticsSuccess');
};

export const receiveCreateValueStreamSuccess = ({ commit, dispatch }, valueStream = {}) => {
  commit(types.RECEIVE_CREATE_VALUE_STREAM_SUCCESS, valueStream);
  return dispatch('fetchCycleAnalyticsData');
};

export const createValueStream = ({ commit, dispatch, getters }, data) => {
  const { currentGroupPath } = getters;
  commit(types.REQUEST_CREATE_VALUE_STREAM);

  return Api.cycleAnalyticsCreateValueStream(currentGroupPath, data)
    .then(({ data: newValueStream }) => dispatch('receiveCreateValueStreamSuccess', newValueStream))
    .catch(({ response } = {}) => {
      const { data: { message, payload: { errors } } = null } = response;
      commit(types.RECEIVE_CREATE_VALUE_STREAM_ERROR, { message, errors });
    });
};

export const deleteValueStream = ({ commit, dispatch, getters }, valueStreamId) => {
  const { currentGroupPath } = getters;
  commit(types.REQUEST_DELETE_VALUE_STREAM);

  return Api.cycleAnalyticsDeleteValueStream(currentGroupPath, valueStreamId)
    .then(() => commit(types.RECEIVE_DELETE_VALUE_STREAM_SUCCESS))
    .then(() => dispatch('fetchCycleAnalyticsData'))
    .catch(({ response } = {}) => {
      const { data: { message } = null } = response;
      commit(types.RECEIVE_DELETE_VALUE_STREAM_ERROR, message);
    });
};

export const fetchValueStreamData = ({ dispatch }) =>
  Promise.resolve()
    .then(() => dispatch('fetchGroupStagesAndEvents'))
    .then(() => dispatch('stages/fetchStageMedianValues'))
    .then(() => dispatch('durationChart/fetchDurationData'));

export const setSelectedValueStream = ({ commit, dispatch }, valueStream) => {
  commit(types.SET_SELECTED_VALUE_STREAM, valueStream);
  return dispatch(FETCH_VALUE_STREAM_DATA);
};

export const receiveValueStreamsSuccess = (
  { state: { selectedValueStream = null }, commit, dispatch },
  data = [],
) => {
  commit(types.RECEIVE_VALUE_STREAMS_SUCCESS, data);
  if (!selectedValueStream && data.length) {
    const [firstStream] = data;
    return dispatch('setSelectedValueStream', firstStream);
  }
  return dispatch(FETCH_VALUE_STREAM_DATA);
};

export const fetchValueStreams = ({ commit, dispatch, getters, state }) => {
  const {
    featureFlags: { hasCreateMultipleValueStreams = false },
  } = state;
  const { currentGroupPath } = getters;

  if (hasCreateMultipleValueStreams) {
    commit(types.REQUEST_VALUE_STREAMS);

    return Api.cycleAnalyticsValueStreams(currentGroupPath)
      .then(({ data }) => dispatch('receiveValueStreamsSuccess', data))
      .catch(error => {
        const {
          response: { status },
        } = error;
        commit(types.RECEIVE_VALUE_STREAMS_ERROR, status);
        throw error;
      });
  }
  return dispatch(FETCH_VALUE_STREAM_DATA);
};

export const setFilters = ({ dispatch }) => {
  return dispatch('fetchCycleAnalyticsData');
};
