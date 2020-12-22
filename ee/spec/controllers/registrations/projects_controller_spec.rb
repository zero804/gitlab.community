# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Registrations::ProjectsController do
  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:group) }

  describe 'GET #new' do
    subject { get :new }

    context 'with an unauthenticated user' do
      it { is_expected.to have_gitlab_http_status(:redirect) }
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'with an authenticated user' do
      before do
        sign_in(user)
        stub_experiment_for_subject(onboarding_issues: true)
      end

      it { is_expected.to have_gitlab_http_status(:not_found) }

      context 'with a namespace in the URL' do
        subject { get :new, params: { namespace_id: namespace.id } }

        it { is_expected.to have_gitlab_http_status(:not_found) }

        context 'with sufficient access' do
          before do
            namespace.add_owner(user)
          end

          it { is_expected.to have_gitlab_http_status(:ok) }
          it { is_expected.to render_template(:new) }
        end
      end

      context 'with the experiment not enabled for user' do
        before do
          stub_experiment_for_subject(onboarding_issues: false)
        end

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end
    end
  end

  describe 'POST #create' do
    subject { post :create, params: { project: params }.merge(trial_onboarding_flow_params) }

    let_it_be(:trial_onboarding_flow_params) { {} }
    let(:params) { { namespace_id: namespace.id, name: 'New project', path: 'project-path', visibility_level: Gitlab::VisibilityLevel::PRIVATE } }

    context 'with an unauthenticated user' do
      it { is_expected.to have_gitlab_http_status(:redirect) }
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'with an authenticated user' do
      let_it_be(:trial_onboarding_issues_enabled) { false }

      before do
        namespace.add_owner(user)
        sign_in(user)
        stub_experiment_for_subject(onboarding_issues: true, trial_onboarding_issues: trial_onboarding_issues_enabled)
      end

      it 'creates a new project, a "Learn GitLab" project, sets a cookie and redirects to the experience level page' do
        expect { subject }.to change { namespace.projects.pluck(:name) }.from([]).to(['New project', s_('Learn GitLab')])

        Sidekiq::Worker.drain_all

        expect(subject).to have_gitlab_http_status(:redirect)
        expect(subject).to redirect_to(users_sign_up_experience_level_path(namespace_path: namespace.to_param))
        expect(namespace.projects.find_by_name(s_('Learn GitLab'))).to be_import_finished
        expect(cookies[:onboarding_issues_settings]).not_to be_nil
      end

      context 'when the trial onboarding is active' do
        let_it_be(:trial_onboarding_flow_params) { { trial_onboarding_flow: true } }
        let_it_be(:trial_onboarding_issues_enabled) { true }
        let_it_be(:project) { create(:project) }
        let_it_be(:trial_onboarding_context) { { learn_gitlab_project_id: project.id, namespace_id: project.namespace_id } }

        it 'creates a new project, a "Learn GitLab - Gold trial" project, does not set a cookie' do
          expect { subject }.to change { namespace.projects.pluck(:name) }.from([]).to(['New project', s_('Learn GitLab - Gold trial')])
          Sidekiq::Worker.drain_all

          expect(subject).to have_gitlab_http_status(:redirect)
          expect(namespace.projects.find_by_name(s_('Learn GitLab - Gold trial'))).to be_import_finished
          expect(cookies[:onboarding_issues_settings]).to be_nil
        end

        it 'records context and redirects to the trial getting started page' do
          expect_next_instance_of(::Projects::GitlabProjectsImportService) do |service|
            expect(service).to receive(:execute).and_return(project)
          end
          Sidekiq::Worker.drain_all
          expect(controller).to receive(:record_experiment_user).with(:trial_onboarding_issues, trial_onboarding_context)
          expect(subject).to redirect_to(trial_getting_started_users_sign_up_welcome_path(learn_gitlab_project_id: project.id))
        end
      end

      context 'when the project cannot be saved' do
        let(:params) { { name: '', path: '' } }

        it 'does not create a project' do
          expect { subject }.not_to change { Project.count }
        end

        it { is_expected.to have_gitlab_http_status(:ok) }
        it { is_expected.to render_template(:new) }
      end

      context 'with the experiment not enabled for user' do
        before do
          stub_experiment_for_subject(onboarding_issues: false)
        end

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end
    end
  end
end
