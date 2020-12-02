# frozen_string_literal: true
class MergeRequestAssigneeEntity < ::API::Entities::UserBasic
  expose :can_merge do |assignee, options|
    options[:merge_request]&.can_be_merged_by?(assignee)
  end

  expose :availability, if: -> (*) { status_loaded? } do |user|
    user.status.availability
  end

  private

  def status_loaded?
    object.association(:status).loaded?
  end
end

MergeRequestAssigneeEntity.prepend_if_ee('EE::MergeRequestAssigneeEntity')
