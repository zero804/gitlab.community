# frozen_string_literal: true

require 'spec_helper'

describe Git::WikiPushService, services: true do
  include RepoHelpers

  let_it_be(:key_id) { create(:key, user: current_user).shell_id }
  let_it_be(:project) { create(:project, :wiki_repo) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:git_wiki) { project.wiki.wiki }
  let_it_be(:repository) { git_wiki.repository }

  describe '#execute' do
    context 'the push contains more than the permitted number of changes' do
      def run_service
        process_changes { described_class::MAX_CHANGES.succ.times { write_new_page } }
      end

      it 'creates only MAX_CHANGES events' do
        expect { run_service }.to change(Event, :count).by(described_class::MAX_CHANGES)
      end
    end

    context 'default_branch collides with a tag' do
      it 'creates only one event' do
        base_sha = current_sha
        write_new_page

        service = create_service(base_sha, ['refs/heads/master', 'refs/tags/master'])

        expect { service.execute }.to change(Event, :count).by(1)
      end
    end

    describe 'successfully creating events' do
      let(:count) { Event::WIKI_ACTIONS.size }

      def run_service
        wiki_page_a = create(:wiki_page, project: project)
        wiki_page_b = create(:wiki_page, project: project)

        process_changes do
          write_new_page
          update_page(wiki_page_a.title)
          delete_page(wiki_page_b.page.path)
        end
      end

      it 'creates one event for every wiki action' do
        expect { run_service }.to change(Event, :count).by(count)
      end

      it 'handles all known actions' do
        run_service

        expect(Event.last(count).pluck(:action)).to match_array(Event::WIKI_ACTIONS)
      end
    end

    context 'two pages have been created' do
      def run_service
        process_changes do
          write_new_page
          write_new_page
        end
      end

      it 'creates two events' do
        expect { run_service }.to change(Event, :count).by(2)
      end

      it 'creates two metadata records' do
        expect { run_service }.to change(WikiPage::Meta, :count).by(2)
      end

      it 'creates appropriate events' do
        run_service

        expect(Event.last(2)).to all(have_attributes(wiki_page?: true, action: Event::CREATED))
      end
    end

    context 'a non-page file as been added' do
      it 'does not create events, or WikiPage metadata' do
        expect do
          process_changes { write_non_page }
        end.not_to change { [Event.count, WikiPage::Meta.count] }
      end
    end

    context 'one page, and one non-page have been created' do
      def run_service
        process_changes do
          write_new_page
          write_non_page
        end
      end

      it 'creates a wiki page creation event' do
        expect { run_service }.to change(Event, :count).by(1)

        expect(Event.last).to have_attributes(wiki_page?: true, action: Event::CREATED)
      end

      it 'creates one metadata record' do
        expect { run_service }.to change(WikiPage::Meta, :count).by(1)
      end
    end

    context 'one page has been added, and then updated' do
      def run_service
        process_changes do
          title = write_new_page
          update_page(title)
        end
      end

      it 'creates just a single event' do
        expect { run_service }.to change(Event, :count).by(1)
      end

      it 'creates just one metadata record' do
        expect { run_service }.to change(WikiPage::Meta, :count).by(1)
      end

      it 'creates a new wiki page creation event' do
        run_service

        expect(Event.last).to have_attributes(
          wiki_page?: true,
          action: Event::CREATED
        )
      end
    end

    context 'when a page we already know about has been updated' do
      let(:wiki_page) { create(:wiki_page, project: project) }

      before do
        create(:wiki_page_meta, :for_wiki_page, wiki_page: wiki_page)
      end

      def run_service
        process_changes { update_page(wiki_page.title) }
      end

      it 'does not create a new meta-data record' do
        expect { run_service }.not_to change(WikiPage::Meta, :count)
      end

      it 'creates a new event' do
        expect { run_service }.to change(Event, :count).by(1)
      end

      it 'adds an update event' do
        run_service

        expect(Event.last).to have_attributes(
          wiki_page?: true,
          action: Event::UPDATED
        )
      end
    end

    context 'when a page we do not know about has been updated' do
      def run_service
        wiki_page = create(:wiki_page, project: project)
        process_changes { update_page(wiki_page.title) }
      end

      it 'creates a new meta-data record' do
        expect { run_service }.to change(WikiPage::Meta, :count).by(1)
      end

      it 'creates a new event' do
        expect { run_service }.to change(Event, :count).by(1)
      end

      it 'adds an update event' do
        run_service

        expect(Event.last).to have_attributes(
          wiki_page?: true,
          action: Event::UPDATED
        )
      end
    end

    context 'when a page we do not know about has been deleted' do
      def run_service
        wiki_page = create(:wiki_page, project: project)
        process_changes { delete_page(wiki_page.page.path) }
      end

      it 'create a new meta-data record' do
        expect { run_service }.to change(WikiPage::Meta, :count).by(1)
      end

      it 'creates a new event' do
        expect { run_service }.to change(Event, :count).by(1)
      end

      it 'adds an update event' do
        run_service

        expect(Event.last).to have_attributes(
          wiki_page?: true,
          action: Event::DESTROYED
        )
      end
    end

    it 'calls log_error for every event we cannot create' do
      base_sha = current_sha
      count = 3
      count.times { write_new_page }
      message = 'something went very very wrong'
      allow_next_instance_of(WikiPages::EventCreateService, current_user) do |service|
        allow(service).to receive(:execute)
          .with(String, WikiPage, Integer)
          .and_return(ServiceResponse.error(message: message))
      end

      service = create_service(base_sha)

      expect(service).to receive(:log_error).exactly(count).times.with(message)

      service.execute
    end

    describe 'feature flags' do
      shared_examples 'a no-op push' do
        it 'does not create any events' do
          expect { process_changes { write_new_page } }.not_to change(Event, :count)
        end

        it 'does not even look for events to process' do
          base_sha = current_sha
          write_new_page

          service = create_service(base_sha)

          expect(service).not_to receive(:changed_files)

          service.execute
        end
      end

      context 'the wiki_events feature is disabled' do
        before do
          stub_feature_flags(wiki_events: false)
        end

        it_behaves_like 'a no-op push'
      end

      context 'the wiki_events_on_git_push feature is disabled' do
        before do
          stub_feature_flags(wiki_events_on_git_push: false)
        end

        it_behaves_like 'a no-op push'

        context 'but is enabled for a given project' do
          before do
            stub_feature_flags(wiki_events_on_git_push: project)
          end

          it 'creates events' do
            expect { process_changes { write_new_page } }.to change(Event, :count).by(1)
          end
        end
      end
    end
  end

  # In order to construct the correct GitPostReceive object that represents the
  # changes we are applying, we need to describe the changes between old-ref and
  # new-ref. Old ref (the base sha) we have to capture before we perform any
  # changes. Once the changes have been applied, we can execute the service to
  # process them.
  def process_changes(&block)
    base_sha = current_sha
    yield
    create_service(base_sha).execute
  end

  def create_service(base, refs = ['refs/heads/master'])
    changes = post_received(base, refs).changes
    described_class.new(project, current_user, changes: changes)
  end

  def post_received(base, refs)
    change_str = refs.map { |ref| +"#{base} #{current_sha} #{ref}" }.join("\n")
    post_received = ::Gitlab::GitPostReceive.new(project, key_id, change_str, {})
    allow(post_received).to receive(:identify).with(key_id).and_return(current_user)

    post_received
  end

  def current_sha
    repository.gitaly_ref_client.find_branch('master')&.dereferenced_target&.id || Gitlab::Git::BLANK_SHA
  end

  # It is important not to re-use the WikiPage services here, since they create
  # events - these helper methods below are intended to simulate actions on the repo
  # that have not gone through our services.

  def write_new_page
    generate(:wiki_page_title).tap { |t| git_wiki.write_page(t, 'markdown', 'Hello', commit_details) }
  end

  # We write something to the wiki-repo that is not a page - as, for example, an
  # attachment. This will appear as a raw-diff change, but wiki.find_page will
  # return nil.
  def write_non_page
    params = {
      file_name: 'attachment.log',
      file_content: 'some stuff',
      branch_name: 'master'
    }
    ::Wikis::CreateAttachmentService.new(container: project, current_user: project.owner, params: params).execute
  end

  def update_page(title)
    page = git_wiki.page(title: title)
    git_wiki.update_page(page.path, title, 'markdown', 'Hey', commit_details)
  end

  def delete_page(path)
    git_wiki.delete_page(path, commit_details)
  end

  def commit_details
    create(:git_wiki_commit_details, author: current_user)
  end
end
