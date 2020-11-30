import Vue from 'vue';
import $ from 'jquery';
import JiraConnectApp from './components/app.vue';
import createStore from './store';

/**
 * Initialize form handlers for the Jira Connect app
 * @param {object} store - object created with `createStore` builder
 */
const initJiraFormHandlers = store => {
  const reqComplete = () => {
    AP.navigator.reload();
  };

  const reqFailed = (res, fallbackErrorMessage) => {
    const { responseJSON: { error = fallbackErrorMessage } = {} } = res || {};

    store.setErrorMessage(error);
  };

  AP.getLocation(location => {
    $('.js-jira-connect-sign-in').each(function updateSignInLink() {
      const updatedLink = `${$(this).attr('href')}?return_to=${location}`;
      $(this).attr('href', updatedLink);
    });
  });

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
  const store = createStore();
  const el = document.querySelector('.js-jira-connect-app');

  initJiraFormHandlers(store);

  return new Vue({
    el,
    data: {
      state: store.state,
    },
    render(createElement) {
      return createElement(JiraConnectApp, {});
    },
  });
}

document.addEventListener('DOMContentLoaded', initJiraConnect);
