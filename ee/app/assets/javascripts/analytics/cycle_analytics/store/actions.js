import Api from 'ee/api';
import { deprecatedCreateFlash as createFlash } from '~/flash';
import { __, sprintf } from '~/locale';
import httpStatus from '~/lib/utils/http_status';
import * as types from './mutation_types';
import { removeFlash, handleErrorOrRethrow, isStageNameExistsError } from '../utils';

const appendExtension = path => (path.indexOf('.') > -1 ? path : `${path}.json`);

export const setPaths = ({ dispatch }, options) => {
  const { group, milestonesPath = '', labelsPath = '' } = options;
  // TODO: After we remove instance VSA we can rely on the paths from the BE
  // https://gitlab.com/gitlab-org/gitlab/-/issues/223735
  const groupPath = group?.parentId || group?.fullPath || '';
  const milestonesEndpoint = milestonesPath || `/groups/${groupPath}/-/milestones`;
  const labelsEndpoint = labelsPath || `/groups/${groupPath}/-/labels`;

  return dispatch('filters/setEndpoints', {
    labelsEndpoint: appendExtension(labelsEndpoint),
    milestonesEndpoint: appendExtension(milestonesEndpoint),
    groupEndpoint: groupPath,
  });
};

export const setFeatureFlags = ({ commit }, featureFlags) =>
  commit(types.SET_FEATURE_FLAGS, featureFlags);

export const setSelectedGroup = ({ commit, dispatch }, group) => {
  commit(types.SET_SELECTED_GROUP, group);
  return dispatch('filters/initialize', { groupPath: group.full_path });
};

export const setSelectedProjects = ({ commit }, projects) =>
  commit(types.SET_SELECTED_PROJECTS, projects);

export const setSelectedStage = ({ commit }, stage) => commit(types.SET_SELECTED_STAGE, stage);

export const setDateRange = ({ commit, dispatch }, { skipFetch = false, startDate, endDate }) => {
  commit(types.SET_DATE_RANGE, { startDate, endDate });

  if (skipFetch) return false;

  return dispatch('fetchCycleAnalyticsData');
};

export const requestStageData = ({ commit }) => commit(types.REQUEST_STAGE_DATA);
export const receiveStageDataSuccess = ({ commit }, data) => {
  commit(types.RECEIVE_STAGE_DATA_SUCCESS, data);
};

export const receiveStageDataError = ({ commit }) => {
  commit(types.RECEIVE_STAGE_DATA_ERROR);
  createFlash(__('There was an error fetching data for the selected stage'));
};

export const fetchStageData = ({ dispatch, getters }, stageId) => {
  const { cycleAnalyticsRequestParams = {}, currentValueStreamId, currentGroupPath } = getters;
  dispatch('requestStageData');

  return Api.cycleAnalyticsStageEvents({
    groupId: currentGroupPath,
    valueStreamId: currentValueStreamId,
    stageId,
    cycleAnalyticsRequestParams,
  })
    .then(({ data }) => dispatch('receiveStageDataSuccess', data))
    .catch(error => dispatch('receiveStageDataError', error));
};

export const requestStageMedianValues = ({ commit }) => commit(types.REQUEST_STAGE_MEDIANS);
export const receiveStageMedianValuesSuccess = ({ commit }, data) => {
  commit(types.RECEIVE_STAGE_MEDIANS_SUCCESS, data);
};

export const receiveStageMedianValuesError = ({ commit }) => {
  commit(types.RECEIVE_STAGE_MEDIANS_ERROR);
  createFlash(__('There was an error fetching median data for stages'));
};

const fetchStageMedian = ({ groupId, valueStreamId, stageId, params }) =>
  Api.cycleAnalyticsStageMedian({ groupId, valueStreamId, stageId, params }).then(({ data }) => ({
    id: stageId,
    ...data,
  }));

export const fetchStageMedianValues = ({ dispatch, getters }) => {
  const {
    currentGroupPath,
    cycleAnalyticsRequestParams,
    activeStages,
    currentValueStreamId,
  } = getters;
  const stageIds = activeStages.map(s => s.slug);

  dispatch('requestStageMedianValues');
  return Promise.all(
    stageIds.map(stageId =>
      fetchStageMedian({
        groupId: currentGroupPath,
        valueStreamId: currentValueStreamId,
        stageId,
        cycleAnalyticsRequestParams,
      }),
    ),
  )
    .then(data => dispatch('receiveStageMedianValuesSuccess', data))
    .catch(error =>
      handleErrorOrRethrow({
        error,
        action: () => dispatch('receiveStageMedianValuesError', error),
      }),
    );
};

export const requestCycleAnalyticsData = ({ commit }) => commit(types.REQUEST_CYCLE_ANALYTICS_DATA);

export const receiveCycleAnalyticsDataSuccess = ({ commit, dispatch }) => {
  commit(types.RECEIVE_CYCLE_ANALYTICS_DATA_SUCCESS);
  dispatch('typeOfWork/fetchTopRankedGroupLabels');
};

export const receiveCycleAnalyticsDataError = ({ commit }, { response }) => {
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

export const setDefaultSelectedStage = ({ dispatch, getters }) => {
  const { activeStages = [] } = getters;
  if (activeStages?.length) {
    const [firstActiveStage] = activeStages;
    return Promise.all([
      dispatch('setSelectedStage', firstActiveStage),
      dispatch('fetchStageData', firstActiveStage.slug),
    ]);
  }

  createFlash(__('There was an error while fetching value stream analytics data.'));
  return Promise.resolve();
};

export const receiveGroupStagesSuccess = ({ commit, dispatch }, stages) => {
  commit(types.RECEIVE_GROUP_STAGES_SUCCESS, stages);
  return dispatch('setDefaultSelectedStage');
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
    data: {
      start_date: created_after,
      project_ids,
    },
  })
    .then(({ data: { stages = [], events = [] } }) => {
      dispatch('receiveGroupStagesSuccess', stages);
      dispatch('customStages/setStageEvents', events);
    })
    .catch(error =>
      handleErrorOrRethrow({
        error,
        action: () => dispatch('receiveGroupStagesError', error),
      }),
    );
};

export const requestUpdateStage = ({ commit }) => commit(types.REQUEST_UPDATE_STAGE);
export const receiveUpdateStageSuccess = ({ commit, dispatch }, updatedData) => {
  commit(types.RECEIVE_UPDATE_STAGE_SUCCESS);
  createFlash(__('Stage data updated'), 'notice');
  return Promise.resolve()
    .then(() => dispatch('fetchGroupStagesAndEvents'))
    .then(() => dispatch('customStages/showEditForm', updatedData))
    .catch(() => {
      createFlash(__('There was a problem refreshing the data, please try again'));
    });
};

export const receiveUpdateStageError = (
  { commit, dispatch },
  { status, responseData: { errors = null } = {}, data = {} },
) => {
  commit(types.RECEIVE_UPDATE_STAGE_ERROR, { errors, data });

  const { name = null } = data;
  const message =
    name && isStageNameExistsError({ status, errors })
      ? sprintf(__(`'%{name}' stage already exists`), { name })
      : __('There was a problem saving your custom stage, please try again');

  createFlash(__(message));
  return dispatch('customStages/setStageFormErrors', errors);
};

export const updateStage = ({ dispatch, getters }, { id, ...params }) => {
  const { currentGroupPath, currentValueStreamId } = getters;

  dispatch('requestUpdateStage');
  dispatch('customStages/setSavingCustomStage');

  return Api.cycleAnalyticsUpdateStage({
    groupId: currentGroupPath,
    valueStreamId: currentValueStreamId,
    stageId: id,
    data: params,
  })
    .then(({ data }) => dispatch('receiveUpdateStageSuccess', data))
    .catch(({ response: { status = httpStatus.BAD_REQUEST, data: responseData } = {} }) =>
      dispatch('receiveUpdateStageError', { status, responseData, data: { id, ...params } }),
    );
};

export const requestRemoveStage = ({ commit }) => commit(types.REQUEST_REMOVE_STAGE);
export const receiveRemoveStageSuccess = ({ commit, dispatch }) => {
  commit(types.RECEIVE_REMOVE_STAGE_RESPONSE);
  createFlash(__('Stage removed'), 'notice');
  return dispatch('fetchCycleAnalyticsData');
};

export const receiveRemoveStageError = ({ commit }) => {
  commit(types.RECEIVE_REMOVE_STAGE_RESPONSE);
  createFlash(__('There was an error removing your custom stage, please try again'));
};

export const removeStage = ({ dispatch, getters }, stageId) => {
  const { currentGroupPath, currentValueStreamId } = getters;
  dispatch('requestRemoveStage');

  return Api.cycleAnalyticsRemoveStage({
    groupId: currentGroupPath,
    valueStreamId: currentValueStreamId,
    stageId,
  })
    .then(() => dispatch('receiveRemoveStageSuccess'))
    .catch(error => dispatch('receiveRemoveStageError', error));
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
    selectedAssignees,
    selectedLabels,
  } = initialData;
  commit(types.SET_FEATURE_FLAGS, featureFlags);

  if (initialData.group?.fullPath) {
    return Promise.all([
      dispatch('setPaths', { group: initialData.group, milestonesPath, labelsPath }),
      dispatch('filters/initialize', {
        selectedAuthor,
        selectedMilestone,
        selectedAssignees,
        selectedLabels,
      }),
      dispatch('durationChart/setLoading', true),
      dispatch('typeOfWork/setLoading', true),
    ])
      .then(() => dispatch('fetchCycleAnalyticsData'))
      .then(() => dispatch('initializeCycleAnalyticsSuccess'));
  }
  return dispatch('initializeCycleAnalyticsSuccess');
};

export const requestReorderStage = ({ commit }) => commit(types.REQUEST_REORDER_STAGE);

export const receiveReorderStageSuccess = ({ commit }) =>
  commit(types.RECEIVE_REORDER_STAGE_SUCCESS);

export const receiveReorderStageError = ({ commit }) => {
  commit(types.RECEIVE_REORDER_STAGE_ERROR);
  createFlash(__('There was an error updating the stage order. Please try reloading the page.'));
};

export const reorderStage = ({ dispatch, getters }, initialData) => {
  dispatch('requestReorderStage');
  const { currentGroupPath, currentValueStreamId } = getters;
  const { id, moveAfterId, moveBeforeId } = initialData;

  const params = moveAfterId ? { move_after_id: moveAfterId } : { move_before_id: moveBeforeId };

  return Api.cycleAnalyticsUpdateStage({
    groupId: currentGroupPath,
    valueStreamId: currentValueStreamId,
    stageId: id,
    data: params,
  })
    .then(({ data }) => dispatch('receiveReorderStageSuccess', data))
    .catch(({ response: { status = httpStatus.BAD_REQUEST, data: responseData } = {} }) =>
      dispatch('receiveReorderStageError', { status, responseData }),
    );
};

export const receiveCreateValueStreamSuccess = ({ commit, dispatch }) => {
  commit(types.RECEIVE_CREATE_VALUE_STREAM_SUCCESS);
  return dispatch('fetchCycleAnalyticsData');
};

export const createValueStream = ({ commit, dispatch, getters }, data) => {
  const { currentGroupPath } = getters;
  commit(types.REQUEST_CREATE_VALUE_STREAM);

  return Api.cycleAnalyticsCreateValueStream(currentGroupPath, data)
    .then(() => dispatch('receiveCreateValueStreamSuccess'))
    .catch(({ response } = {}) => {
      const { data: { message, payload: { errors } } = null } = response;
      commit(types.RECEIVE_CREATE_VALUE_STREAM_ERROR, { message, errors });
    });
};

export const fetchValueStreamData = ({ dispatch }) =>
  Promise.resolve()
    .then(() => dispatch('fetchGroupStagesAndEvents'))
    .then(() => dispatch('fetchStageMedianValues'))
    .then(() => dispatch('durationChart/fetchDurationData'));

export const setSelectedValueStream = ({ commit, dispatch }, streamId) => {
  commit(types.SET_SELECTED_VALUE_STREAM, streamId);
  return dispatch('fetchValueStreamData');
};

export const receiveValueStreamsSuccess = ({ commit, dispatch }, data = []) => {
  commit(types.RECEIVE_VALUE_STREAMS_SUCCESS, data);
  if (data.length) {
    const [firstStream] = data;
    return dispatch('setSelectedValueStream', firstStream.id);
  }
  return Promise.resolve();
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
  return dispatch('fetchValueStreamData');
};

export const setFilters = ({ dispatch }) => {
  return dispatch('fetchCycleAnalyticsData');
};
