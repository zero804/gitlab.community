# frozen_string_literal: true

module EE
  module Registrations
    module WelcomeController
      extend ::Gitlab::Utils::Override

      prepended do
        skip_before_action :authenticate_user!, :required_signup_info, :check_two_factor_requirement, only: [:trial_getting_started]
      end

      def trial_getting_started
        render :trial_getting_started, locals: { learn_gitlab_project: learn_gitlab_project }
      end

      private

      override :update_params
      def update_params
        clean_params = super.merge(params.require(:user).permit(:email_opted_in))

        clean_params[:email_opted_in] = '1' if clean_params[:setup_for_company] == 'true'

        if clean_params[:email_opted_in] == '1'
          clean_params[:email_opted_in_ip] = request.remote_ip
          clean_params[:email_opted_in_source_id] = User::EMAIL_OPT_IN_SOURCE_ID_GITLAB_COM
          clean_params[:email_opted_in_at] = Time.zone.now
        end

        clean_params
      end

      def learn_gitlab_project
        ::Project.find(params[:learn_gitlab_project_id])
      end
    end
  end
end
