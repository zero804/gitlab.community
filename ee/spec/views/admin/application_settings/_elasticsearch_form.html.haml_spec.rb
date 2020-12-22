# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/_elasticsearch_form' do
  let_it_be(:admin) { create(:admin) }
  let(:page) { Capybara::Node::Simple.new(rendered) }
  let(:pause_indexing) { false }
  let(:pending_migrations) { false }

  before do
    assign(:application_setting, application_setting)
    allow(view).to receive(:current_user) { admin }
    allow(view).to receive(:expanded) { true }
  end

  context 'es indexing' do
    let(:application_setting) { build(:application_setting) }
    let(:button_text) { 'Index all projects' }

    before do
      allow(Gitlab::CurrentSettings).to(receive(:elasticsearch_indexing?)).and_return(es_indexing)
      allow(Gitlab::CurrentSettings).to(receive(:elasticsearch_pause_indexing?)).and_return(pause_indexing)
      allow(Elastic::DataMigrationService).to(receive(:pending_migrations?)).and_return(pending_migrations)
    end

    context 'indexing is enabled' do
      let(:es_indexing) { true }

      it 'hides index button when indexing is disabled' do
        render

        expect(rendered).to have_css('a.btn-success', text: button_text)
      end

      it 'renders an enabled pause checkbox' do
        render

        expect(rendered).to have_css('input[id=application_setting_elasticsearch_pause_indexing]')
        expect(rendered).not_to have_css('input[id=application_setting_elasticsearch_pause_indexing][disabled="disabled"]')
      end

      context 'pending migrations' do
        let(:pending_migrations) { true }
        let(:pause_indexing) { true }

        it 'renders a disabled pause checkbox' do
          render

          expect(rendered).to have_css('input[id=application_setting_elasticsearch_pause_indexing][disabled="disabled"]')
        end
      end
    end

    context 'indexing is disabled' do
      let(:es_indexing) { false }

      it 'shows index button when indexing is enabled' do
        render

        expect(rendered).not_to have_css('a.btn-success', text: button_text)
      end

      it 'renders a disabled pause checkbox' do
        render

        expect(rendered).to have_css('input[id=application_setting_elasticsearch_pause_indexing][disabled="disabled"]')
      end
    end
  end

  context 'when elasticsearch_aws_secret_access_key is not set' do
    let(:application_setting) { build(:application_setting) }

    it 'has field with "AWS Secret Access Key" label and no value' do
      render
      expect(rendered).to have_field('AWS Secret Access Key', type: 'password')
      expect(page.find_field('AWS Secret Access Key').value).to be_blank
    end
  end

  context 'when elasticsearch_aws_secret_access_key is set' do
    let(:application_setting) { build(:application_setting, elasticsearch_aws_secret_access_key: 'elasticsearch_aws_secret_access_key') }

    it 'has field with "Enter new AWS Secret Access Key" label and no value' do
      render
      expect(rendered).to have_field('Enter new AWS Secret Access Key', type: 'password')
      expect(page.find_field('Enter new AWS Secret Access Key').value).to be_blank
    end
  end

  context 'zero-downtime elasticsearch reindexing' do
    let(:application_setting) { build(:application_setting) }

    before do
      assign(:elasticsearch_reindexing_task, task)
    end

    context 'without extended details' do
      let(:task) { build(:elastic_reindexing_task) }

      it 'renders the task' do
        render

        expect(rendered).to include("State: #{task.state}")
        expect(rendered).not_to include("Task ID:")
        expect(rendered).not_to include("Error:")
        expect(rendered).not_to include("Expected documents:")
        expect(rendered).not_to include("Documents reindexed:")
      end
    end

    context 'with extended details' do
      let(:task) { build(:elastic_reindexing_task, state: :reindexing, elastic_task: 'elastic-task-id', error_message: 'error-message', documents_count_target: 5, documents_count: 10) }

      it 'renders the task' do
        render

        expect(rendered).to include("State: #{task.state}")
        expect(rendered).to include("Task ID: #{task.elastic_task}")
        expect(rendered).to include("Error: #{task.error_message}")
        expect(rendered).to include("Expected documents: #{task.documents_count}")
        expect(rendered).to include("Documents reindexed: #{task.documents_count_target} (50.0%)")
      end
    end

    context 'with extended details, but without documents_count_target' do
      let(:task) { build(:elastic_reindexing_task, state: :reindexing, elastic_task: 'elastic-task-id', documents_count: 10) }

      it 'renders the task' do
        render

        expect(rendered).to include("State: #{task.state}")
        expect(rendered).to include("Task ID: #{task.elastic_task}")
        expect(rendered).to include("Expected documents: #{task.documents_count}")
        expect(rendered).not_to include("Error:")
        expect(rendered).not_to include("Documents reindexed:")
      end
    end
  end

  context 'when there are elasticsearch indexed namespaces' do
    let(:application_setting) { build(:application_setting, elasticsearch_limit_indexing: true) }

    before do
      create(:elasticsearch_indexed_namespace)
      create(:elasticsearch_indexed_namespace)
      create(:elasticsearch_indexed_namespace)
    end

    it 'shows the input' do
      render
      expect(rendered).to have_field('application_setting[elasticsearch_namespace_ids]')
    end

    context 'when there are too many elasticsearch indexed namespaces' do
      before do
        create_list :elasticsearch_indexed_namespace, 60
      end

      it 'hides the input' do
        render
        expect(rendered).not_to have_field('application_setting[elasticsearch_namespace_ids]')
      end
    end
  end

  context 'when there are elasticsearch indexed projects' do
    let(:application_setting) { build(:application_setting, elasticsearch_limit_indexing: true) }

    before do
      create(:elasticsearch_indexed_project)
      create(:elasticsearch_indexed_project)
      create(:elasticsearch_indexed_project)
    end

    it 'shows the input' do
      render
      expect(rendered).to have_field('application_setting[elasticsearch_project_ids]')
    end

    context 'when there are too many elasticsearch indexed projects' do
      before do
        create_list :elasticsearch_indexed_project, 60
      end

      it 'hides the input' do
        render
        expect(rendered).not_to have_field('application_setting[elasticsearch_project_ids]')
      end
    end
  end
end
