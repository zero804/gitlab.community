# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::ReindexingTask, type: :model do
  it 'only allows one running task at a time' do
    expect { create(:elastic_reindexing_task, state: :success) }.not_to raise_error
    expect { create(:elastic_reindexing_task) }.not_to raise_error
    expect { create(:elastic_reindexing_task) }.to raise_error(/violates unique constraint/)
  end

  it 'sets in_progress flag' do
    task = create(:elastic_reindexing_task, state: :success)
    expect(task.in_progress).to eq(false)

    task.update!(state: :reindexing)
    expect(task.in_progress).to eq(true)
  end

  describe '.drop_old_indices!' do
    let(:task_1) { create(:elastic_reindexing_task, state: :reindexing, delete_original_index_at: 1.day.ago) }
    let(:task_2) { create(:elastic_reindexing_task, state: :success, delete_original_index_at: nil) }
    let(:task_3) { create(:elastic_reindexing_task, state: :success, delete_original_index_at: 1.day.ago) }
    let(:task_4) { create(:elastic_reindexing_task, state: :success, delete_original_index_at: 5.days.ago) }
    let(:task_5) { create(:elastic_reindexing_task, state: :success, delete_original_index_at: 14.days.from_now) }
    let(:tasks_for_deletion) { [task_3, task_4] }
    let(:other_tasks) { [task_1, task_2, task_5] }

    before do
      [task_1, task_2, task_3, task_4, task_5].each_with_index do |task, i|
        create(:elastic_reindexing_subtask, index_name_from: "index_#{i}", elastic_reindexing_task: task)
      end
    end

    it 'deletes the correct indices' do
      other_tasks.each do |task|
        expect(Gitlab::Elastic::Helper.default).not_to receive(:delete_index).with(index_name: task.subtasks.first.index_name_from)
      end

      tasks_for_deletion.each do |task|
        expect(Gitlab::Elastic::Helper.default).to receive(:delete_index).with(index_name: task.subtasks.first.index_name_from).and_return(true)
      end

      described_class.drop_old_indices!

      tasks_for_deletion.each do |task|
        expect(task.reload.state).to eq('original_index_deleted')
      end
    end
  end
end
