# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Merge request creation from fork', :smoke do
      let!(:merge_request) do
        Resource::MergeRequestFromFork.fabricate_via_browser_ui! do |merge_request|
          merge_request.fork_branch = 'feature-branch'
        end
      end

      it 'can merge feature branch fork to mainline', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/928' do
        Flow::Login.while_signed_in do
          merge_request.visit!

          Page::MergeRequest::Show.perform do |merge_request|
            merge_request.merge!

            expect(merge_request).to have_content('The changes were merged')
          end
        end
      end
    end
  end
end
