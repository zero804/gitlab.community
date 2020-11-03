import * as types from './mutation_types';

export const setOverride = ({ commit }, override) => commit(types.SET_OVERRIDE, override);
export const setIsSaving = ({ commit }, isSaving) => commit(types.SET_IS_SAVING, isSaving);
export const setIsTesting = ({ commit }, isTesting) => commit(types.SET_IS_TESTING, isTesting);
export const integrationTestData = ({ commit }, integrationData) => commit(types.INTEGRATION_TEST_DATA, integrationData);
