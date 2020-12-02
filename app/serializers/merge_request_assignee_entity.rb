# frozen_string_literal: true
class MergeRequestAssigneeEntity < ::API::Entities::UserBasic
  include ProfilesHelper

  expose :can_merge do |assignee, options|
    options[:merge_request]&.can_be_merged_by?(assignee)
  end

  expose :is_busy do |user|
    pp user.status
    status_loaded? && user_status_set_to_busy?(user.status)
  end

  private

  def status_loaded?
    object.association(:status).loaded?
  end
end

MergeRequestAssigneeEntity.prepend_if_ee('EE::MergeRequestAssigneeEntity')
