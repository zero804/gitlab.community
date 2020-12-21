# frozen_string_literal: true

FactoryBot.define do
  factory :elastic_reindexing_subtask, class: 'Elastic::ReindexingSubtask' do
    association :elastic_reindexing_task, in_progress: false, state: :success
    index_name_from { 'old_index_name' }
    index_name_to { 'new_index_name' }
    elastic_task { 'elastic_task_id' }
    alias_name { 'alias_name' }
  end
end
