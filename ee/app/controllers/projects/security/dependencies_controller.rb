# frozen_string_literal: true

module Projects
  module Security
    class DependenciesController < Projects::ApplicationController
      before_action :authorize_read_dependencies!

      def index
        respond_to do |format|
          format.json do
            ::Gitlab::UsageCounters::DependencyList.increment(project.id)

            render json: serializer.represent(dependencies, build: report_service.build)
          end
        end
      end

      private

      def collect_dependencies
        found_dependencies = report_service.able_to_fetch? ? service.execute : []
        ::Gitlab::DependenciesCollection.new(found_dependencies)
      end

      def dependencies
        @dependencies ||= collect_dependencies
      end

      def match_disallowed(param, value)
        param == :sort_by && !value.in?(::Security::DependencyListService::SORT_BY_VALUES) ||
          param == :sort && !value.in?(::Security::DependencyListService::SORT_VALUES) ||
          param == :filter && !value.in?(::Security::DependencyListService::FILTER_VALUES)
      end

      def pipeline
        @pipeline ||= report_service.pipeline
      end

      def query_params
        params.permit(:sort, :sort_by, :filter).delete_if do |key, value|
          match_disallowed(key, value)
        end
      end

      def report_service
        @report_service ||= ::Security::ReportFetchService.new(project, ::Ci::JobArtifact.dependency_list_reports)
      end

      def serializer
        serializer = ::DependencyListSerializer.new(project: project, user: current_user)
        serializer = serializer.with_pagination(request, response) if params[:page]
        serializer
      end

      def service
        ::Security::DependencyListService.new(pipeline: pipeline, params: query_params)
      end
    end
  end
end
