# frozen_string_literal: true

module Gitlab
  module QuickActions
    module MergeRequestActions
      extend ActiveSupport::Concern
      include Gitlab::QuickActions::Dsl

      included do
        # MergeRequest only quick actions definitions
        desc do
          if preferred_strategy = preferred_auto_merge_strategy(quick_action_target)
            _("Merge automatically (%{strategy})") % { strategy: preferred_strategy.humanize }
          else
            _("Merge immediately")
          end
        end
        explanation do
          if preferred_strategy = preferred_auto_merge_strategy(quick_action_target)
            _("Schedules to merge this merge request (%{strategy}).") % { strategy: preferred_strategy.humanize }
          else
            _('Merges this merge request immediately.')
          end
        end
        execution_message do
          if preferred_strategy = preferred_auto_merge_strategy(quick_action_target)
            _("Scheduled to merge this merge request (%{strategy}).") % { strategy: preferred_strategy.humanize }
          else
            _('Merged this merge request.')
          end
        end
        types MergeRequest
        condition do
          quick_action_target.persisted? &&
            merge_orchestration_service.can_merge?(quick_action_target)
        end
        command :merge do
          @updates[:merge] = params[:merge_request_diff_head_sha]
        end

        desc 'Toggle the Draft status'
        explanation do
          noun = quick_action_target.to_ability_name.humanize(capitalize: false)
          if quick_action_target.work_in_progress?
            _("Unmarks this %{noun} as a draft.")
          else
            _("Marks this %{noun} as a draft.")
          end % { noun: noun }
        end
        execution_message do
          noun = quick_action_target.to_ability_name.humanize(capitalize: false)
          if quick_action_target.work_in_progress?
            _("Unmarked this %{noun} as a draft.")
          else
            _("Marked this %{noun} as a draft.")
          end % { noun: noun }
        end

        types MergeRequest
        condition do
          quick_action_target.respond_to?(:work_in_progress?) &&
            # Allow it to mark as WIP on MR creation page _or_ through MR notes.
            (quick_action_target.new_record? || current_user.can?(:"update_#{quick_action_target.to_ability_name}", quick_action_target))
        end
        command :draft, :wip do
          @updates[:wip_event] = quick_action_target.work_in_progress? ? 'unwip' : 'wip'
        end

        desc _('Set target branch')
        explanation do |branch_name|
          _('Sets target branch to %{branch_name}.') % { branch_name: branch_name }
        end
        execution_message do |branch_name|
          _('Set target branch to %{branch_name}.') % { branch_name: branch_name }
        end
        params '<Local branch name>'
        types MergeRequest
        condition do
          quick_action_target.respond_to?(:target_branch) &&
            (current_user.can?(:"update_#{quick_action_target.to_ability_name}", quick_action_target) ||
              quick_action_target.new_record?)
        end
        parse_params do |target_branch_param|
          target_branch_param.strip
        end
        command :target_branch do |branch_name|
          @updates[:target_branch] = branch_name if project.repository.branch_exists?(branch_name)
        end

        desc _('Submit a review')
        explanation _('Submit the current review.')
        types MergeRequest
        condition do
          quick_action_target.persisted?
        end
        command :submit_review do
          next if params[:review_id]

          result = DraftNotes::PublishService.new(quick_action_target, current_user).execute
          @execution_message[:submit_review] = if result[:status] == :success
                                                 _('Submitted the current review.')
                                               else
                                                 result[:message]
                                               end
        end

        desc _('Approve a merge request')
        explanation _('Approve the current merge request.')
        types MergeRequest
        condition do
          quick_action_target.persisted? && quick_action_target.can_be_approved_by?(current_user)
        end
        command :approve do
          success = MergeRequests::ApprovalService.new(quick_action_target.project, current_user).execute(quick_action_target)

          next unless success

          @execution_message[:approve] = _('Approved the current merge request.')
        end

        desc do
          if quick_action_target.allows_multiple_reviewers?
            _('Assign reviewer(s)')
          else
            _('Assign reviewer')
          end
        end
        explanation do |users|
          _('Assigns %{reviewer_users_sentence} as %{reviewer_text}.') % { reviewer_users_sentence: reviewer_users_sentence(users),
                                                                           reviewer_text: 'reviewer'.pluralize(users.size) }
        end
        execution_message do |users = nil|
          invalid_users = @invalid_users

          if invalid_users.blank?
            if users.blank?
              _("Failed to assign a reviewer because no user was found.")
            else
              users = [users.first] unless quick_action_target.allows_multiple_reviewers?

              _('Assigned %{reviewer_users_sentence} as %{reviewer_text}.') % { reviewer_users_sentence: reviewer_users_sentence(users),
                                                                                reviewer_text: 'reviewer'.pluralize(users.size) }
            end
          else
            _('%{invalid_users_sentence} %{does_text} have access to review this merge request.') % { invalid_users_sentence: reviewer_users_sentence(invalid_users),
                                                                                                      does_text: invalid_users.size > 1 ? "don't" : "doesn't" }
          end
        end
        params do
          quick_action_target.allows_multiple_reviewers? ? '@user1 @user2' : '@user'
        end
        types MergeRequest
        condition do
          Feature.enabled?(:merge_request_reviewers, project, default_enabled: :yaml) &&
            current_user.can?(:"admin_#{quick_action_target.to_ability_name}", project)
        end
        parse_params do |reviewer_param|
          extract_users(reviewer_param)
        end
        command :assign_reviewer do |users|
          next if users.empty?

          if quick_action_target.allows_multiple_reviewers?
            @invalid_users = users.select { |user| !user_can_review?(user) }

            @updates[:reviewer_ids] ||= quick_action_target.reviewers.map(&:id)
            @updates[:reviewer_ids] |= users.map(&:id) - @invalid_users.map(&:id)
          else
            if user_can_review?(users.first)
              @updates[:reviewer_ids] = [users.first.id]
              @invalid_users = []
            else
              @updates[:reviewer_ids] = []
              @invalid_users = [users.first]
            end
          end
        end

        desc do
          if quick_action_target.allows_multiple_reviewers?
            _('Remove all or specific reviewer(s)')
          else
            _('Remove reviewer')
          end
        end
        explanation do |users = nil|
          reviewers = reviewers_for_removal(users)
          _("Removes %{reviewer_text} %{reviewer_references}.") %
            { reviewer_text: 'reviewer'.pluralize(reviewers.size), reviewer_references: reviewers.map(&:to_reference).to_sentence }
        end
        execution_message do |users = nil|
          reviewers = reviewers_for_removal(users)
          _("Removed %{reviewer_text} %{reviewer_references}.") %
            { reviewer_text: 'reviewer'.pluralize(reviewers.size), reviewer_references: reviewers.map(&:to_reference).to_sentence }
        end
        params do
          quick_action_target.allows_multiple_reviewers? ? '@user1 @user2' : ''
        end
        types MergeRequest
        condition do
          quick_action_target.persisted? &&
            Feature.enabled?(:merge_request_reviewers, project, default_enabled: :yaml) &&
            quick_action_target.reviewers.any? &&
            current_user.can?(:"admin_#{quick_action_target.to_ability_name}", project)
        end
        parse_params do |unassign_reviewer_param|
          # When multiple users are assigned, all will be unassigned if multiple reviewers are no longer allowed
          extract_users(unassign_reviewer_param) if quick_action_target.allows_multiple_reviewers?
        end
        command :unassign_reviewer do |users = nil|
          if quick_action_target.allows_multiple_reviewers? && users&.any?
            @updates[:reviewer_ids] ||= quick_action_target.reviewers.map(&:id)
            @updates[:reviewer_ids] -= users.map(&:id)
          else
            @updates[:reviewer_ids] = []
          end
        end
      end

      def merge_orchestration_service
        @merge_orchestration_service ||= MergeRequests::MergeOrchestrationService.new(project, current_user)
      end

      def preferred_auto_merge_strategy(merge_request)
        merge_orchestration_service.preferred_auto_merge_strategy(merge_request)
      end
    end
  end
end
