import createState from 'ee/ide/stores/modules/terminal_sync/state';
import * as types from 'ee/ide/stores/modules/terminal_sync/mutation_types';
import mutations from 'ee/ide/stores/modules/terminal_sync/mutations';

const TEST_MESSAGE = 'lorem ipsum dolar sit';

describe('ee/ide/stores/modules/terminal_sync/mutations', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe(types.START_LOADING, () => {
    it('sets isLoading and resets error', () => {
      Object.assign(state, {
        isLoading: false,
        isError: true,
      });

      mutations[types.START_LOADING](state);

      expect(state).toEqual(
        expect.objectContaining({
          isLoading: true,
          isError: false,
        }),
      );
    });
  });

  describe(types.SET_ERROR, () => {
    it('sets isLoading and error message', () => {
      Object.assign(state, {
        isLoading: true,
        isError: false,
        message: '',
      });

      mutations[types.SET_ERROR](state, { message: TEST_MESSAGE });

      expect(state).toEqual(
        expect.objectContaining({
          isLoading: false,
          isError: true,
          message: TEST_MESSAGE,
        }),
      );
    });
  });

  describe(types.SET_SUCCESS, () => {
    it('sets isLoading and resets error and is started', () => {
      Object.assign(state, {
        isLoading: true,
        isError: true,
        isStarted: false,
      });

      mutations[types.SET_SUCCESS](state);

      expect(state).toEqual(
        expect.objectContaining({
          isLoading: false,
          isError: false,
          isStarted: true,
        }),
      );
    });
  });

  describe(types.STOP, () => {
    it('sets stop values', () => {
      Object.assign(state, {
        isLoading: true,
        isStarted: true,
      });

      mutations[types.STOP](state);

      expect(state).toEqual(
        expect.objectContaining({
          isLoading: false,
          isStarted: false,
        }),
      );
    });
  });
});
