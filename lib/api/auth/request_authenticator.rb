# frozen_string_literal: true

module API
  module Auth
    class RequestAuthenticator
      include ActiveModel::Validations
      include Gitlab::Utils::StrongMemoize

      attr_reader :froms, :withs

      validates :froms, inclusion: { in: %i[http_basic_auth] }
      validates :withs, inclusion: { in: %i[personal_access_token job_token deploy_token] }

      def initialize(from: [], with: [])
        @froms = Array.wrap(from)
        @withs = Array.wrap(with)
      end

      # returns a User or a DeployToken
      def authenticate
        return unless valid?

        user_from_access_token
      end

      private

      def user_from_access_token
        token = access_token

        return token if token.is_a?(::DeployToken)

        token.user
      end

      def access_token
        return unless raw_token

        withs.find do |with|
          case with
          when :personal_access_token
            PersonalAccessToken.find_by_token(raw)
          when :job_token
            ::Ci::Build.find_by_token(raw)
          when :deploy_token
            DeployToken.active.find_by_token(raw)
          end
        end
      end

      def raw_token
        strong_memoize(:raw_token) do
          froms.find do |from|
            case from
            when :http_basic_auth
              extract_http_basic_auth
            end
          end
        end
      end

      def extract_http_basic_auth
        ActionController::HttpAuthentication::Basic.authenticate do |_, p|
          break p
        end
      end
    end
  end
end
