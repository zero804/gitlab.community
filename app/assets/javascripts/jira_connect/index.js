import Vue from 'vue';
import $ from 'jquery';
import setConfigs from '@gitlab/ui/dist/config';
import App from './components/app.vue';
import Translate from '~/vue_shared/translate';

const store = {
  state: {
    error: '',
  },
  setErrorMessage(errorMessage) {
    this.state.error = errorMessage;
  },
};

/**
 * Initialize necessary form handlers for the Jira Connect app
 */
const initJiraFormHandlers = () => {
  const reqComplete = () => {
    AP.navigator.reload();
  };

  const reqFailed = (res, fallbackErrorMessage) => {
    const { responseJSON: { error = fallbackErrorMessage } = {} } = res || {};

    store.setErrorMessage(error);
    // eslint-disable-next-line no-alert
    alert(error);
  };

  if (typeof AP.getLocation === 'function') {
    AP.getLocation(location => {
      $('.js-jira-connect-sign-in').each(function updateSignInLink() {
        const updatedLink = `${$(this).attr('href')}?return_to=${location}`;
        $(this).attr('href', updatedLink);
      });
    });
  }

  $('#add-subscription-form').on('submit', function onAddSubscriptionForm(e) {
    const actionUrl = $(this).attr('action');
    e.preventDefault();

    AP.context.getToken(token => {
      // eslint-disable-next-line no-jquery/no-ajax
      $.post(actionUrl, {
        jwt: token,
        namespace_path: $('#namespace-input').val(),
        format: 'json',
      })
        .done(reqComplete)
        .fail(err => reqFailed(err, 'Failed to add namespace. Please try again.'));
    });
  });

  $('.remove-subscription').on('click', function onRemoveSubscriptionClick(e) {
    const href = $(this).attr('href');
    e.preventDefault();

    AP.context.getToken(token => {
      // eslint-disable-next-line no-jquery/no-ajax
      $.ajax({
        url: href,
        method: 'DELETE',
        data: {
          jwt: token,
          format: 'json',
        },
      })
        .done(reqComplete)
        .fail(err => reqFailed(err, 'Failed to remove namespace. Please try again.'));
    });
  });
};

function initJiraConnect() {
  setConfigs();
  Vue.use(Translate);

  const el = document.querySelector('.js-jira-connect-app');

  initJiraFormHandlers();

  if (!el) {
    return null;
  }

  const { namespacesEndpoint } = el.dataset;

  return new Vue({
    el,
    data: {
      state: store.state,
    },
    render(createElement) {
      return createElement(App, {
        props: {
          namespacesEndpoint,
        },
      });
    },
  });
}

document.addEventListener('DOMContentLoaded', initJiraConnect);
