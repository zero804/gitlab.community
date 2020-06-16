import Vue from 'vue';
import * as types from './mutation_types';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { FEATURE_FLAG_SCOPE, USER_LIST_SCOPE } from '../../../constants';
import { mapToScopesViewModel } from '../helpers';

const mapFlag = flag => ({ ...flag, scopes: mapToScopesViewModel(flag.scopes || []) });

const updateFlag = (state, flag) => {
  const index = state[FEATURE_FLAG_SCOPE].findIndex(({ id }) => id === flag.id);
  Vue.set(state[FEATURE_FLAG_SCOPE], index, flag);
};

const createPaginationInfo = (state, headers) => {
  let paginationInfo;
  if (Object.keys(headers).length) {
    const normalizedHeaders = normalizeHeaders(headers);
    paginationInfo = parseIntPagination(normalizedHeaders);
  } else {
    paginationInfo = headers;
  }
  return paginationInfo;
};

export default {
  [types.SET_FEATURE_FLAGS_ENDPOINT](state, endpoint) {
    state.endpoint = endpoint;
  },
  [types.SET_FEATURE_FLAGS_OPTIONS](state, options = {}) {
    state.options = options;
  },
  [types.SET_INSTANCE_ID_ENDPOINT](state, endpoint) {
    state.rotateEndpoint = endpoint;
  },
  [types.SET_INSTANCE_ID](state, instance) {
    state.instanceId = instance;
  },
  [types.SET_PROJECT_ID](state, project) {
    state.projectId = project;
  },
  [types.REQUEST_FEATURE_FLAGS](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_FEATURE_FLAGS_SUCCESS](state, response) {
    state.isLoading = false;
    state.hasError = false;
    state[FEATURE_FLAG_SCOPE] = (response.data.feature_flags || []).map(mapFlag);

    const paginationInfo = createPaginationInfo(state, response.headers);
    state.count = {
      ...state.count,
      [FEATURE_FLAG_SCOPE]: paginationInfo?.total ?? state[FEATURE_FLAG_SCOPE].length,
    };
    state.pageInfo = {
      ...state.pageInfo,
      [FEATURE_FLAG_SCOPE]: paginationInfo,
    };
  },
  [types.RECEIVE_FEATURE_FLAGS_ERROR](state) {
    state.isLoading = false;
    state.hasError = true;
  },
  [types.REQUEST_USER_LISTS](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_USER_LISTS_SUCCESS](state, response) {
    state.isLoading = false;
    state.hasError = false;
    state[USER_LIST_SCOPE] = response.data || [];

    const paginationInfo = createPaginationInfo(state, response.headers);
    state.count = {
      ...state.count,
      [USER_LIST_SCOPE]: paginationInfo?.total ?? state[USER_LIST_SCOPE].length,
    };
    state.pageInfo = {
      ...state.pageInfo,
      [USER_LIST_SCOPE]: paginationInfo,
    };
  },
  [types.RECEIVE_USER_LISTS_ERROR](state) {
    state.isLoading = false;
    state.hasError = true;
  },
  [types.REQUEST_ROTATE_INSTANCE_ID](state) {
    state.isRotating = true;
    state.hasRotateError = false;
  },
  [types.RECEIVE_ROTATE_INSTANCE_ID_SUCCESS](
    state,
    {
      data: { token },
    },
  ) {
    state.isRotating = false;
    state.instanceId = token;
    state.hasRotateError = false;
  },
  [types.RECEIVE_ROTATE_INSTANCE_ID_ERROR](state) {
    state.isRotating = false;
    state.hasRotateError = true;
  },
  [types.UPDATE_FEATURE_FLAG](state, flag) {
    updateFlag(state, flag);
  },
  [types.RECEIVE_UPDATE_FEATURE_FLAG_SUCCESS](state, data) {
    updateFlag(state, mapFlag(data));
  },
  [types.RECEIVE_UPDATE_FEATURE_FLAG_ERROR](state, i) {
    const flag = state[FEATURE_FLAG_SCOPE].find(({ id }) => i === id);
    updateFlag(state, { ...flag, active: !flag.active });
  },
};
