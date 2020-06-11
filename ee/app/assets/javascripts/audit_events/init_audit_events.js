import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import AuditEventsApp from './components/audit_events_app.vue';
import createStore from './store';

export default selector => {
  const el = document.querySelector(selector);
  const {
    events,
    isLastPage,
    formPath,
    enabledTokenTypes,
    filterQaSelector,
    tableQaSelector,
  } = el.dataset;

  const store = createStore();
  store.dispatch('initializeAuditEvents');

  return new Vue({
    el,
    store,
    render: createElement =>
      createElement(AuditEventsApp, {
        props: {
          events: JSON.parse(events),
          isLastPage: parseBoolean(isLastPage),
          enabledTokenTypes: JSON.parse(enabledTokenTypes),
          formPath,
          filterQaSelector,
          tableQaSelector,
        },
      }),
  });
};
