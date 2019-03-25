# frozen_string_literal: true

require 'spec_helper'

describe API::Scim do
  let(:user) { create(:user) }
  let(:identity) { create(:group_saml_identity, user: user) }
  let(:group) { identity.saml_provider.group }
  let(:scim_token) { create(:scim_oauth_access_token, group: group) }

  before do
    stub_licensed_features(group_saml: true)

    group.add_owner(user)
  end

  describe 'GET api/scim/v2/groups/:group/Users' do
    context 'without token auth' do
      it 'responds with 401' do
        get scim_api("scim/v2/groups/#{group.full_path}/Users?filter=id eq \"#{identity.extern_uid}\"", token: false)

        expect(response).to have_gitlab_http_status(401)
      end
    end

    it 'responds with an error if there is no filter' do
      get scim_api("scim/v2/groups/#{group.full_path}/Users")

      expect(response).to have_gitlab_http_status(409)
    end

    context 'existing user' do
      it 'responds with 200' do
        get scim_api("scim/v2/groups/#{group.full_path}/Users?filter=id eq \"#{identity.extern_uid}\"")

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['Resources']).not_to be_empty
        expect(json_response['totalResults']).to eq(1)
      end
    end

    context 'no user' do
      it 'responds with 200' do
        get scim_api("scim/v2/groups/#{group.full_path}/Users?filter=id eq \"nonexistent\"")

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['Resources']).to be_empty
        expect(json_response['totalResults']).to eq(0)
      end
    end
  end

  describe 'GET api/scim/v2/groups/:group/Users/:id' do
    it 'responds with 404 if there is no user' do
      get scim_api("scim/v2/groups/#{group.full_path}/Users/123")

      expect(response).to have_gitlab_http_status(404)
    end

    context 'existing user' do
      it 'responds with 200' do
        get scim_api("scim/v2/groups/#{group.full_path}/Users/#{identity.extern_uid}")

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['id']).to eq(identity.extern_uid)
      end
    end
  end

  describe 'PATCH api/scim/v2/groups/:group/Users/:id' do
    it 'responds with 404 if there is no user' do
      patch scim_api("scim/v2/groups/#{group.full_path}/Users/123")

      expect(response).to have_gitlab_http_status(404)
    end

    context 'existing user' do
      context 'extern UID' do
        before do
          params = { Operations: [{ 'op': 'Replace', 'path': 'id', 'value': 'new_uid' }] }.to_query

          patch scim_api("scim/v2/groups/#{group.full_path}/Users/#{identity.extern_uid}?#{params}")
        end

        it 'responds with 204' do
          expect(response).to have_gitlab_http_status(204)
        end

        it 'updates the extern_uid' do
          expect(identity.reload.extern_uid).to eq('new_uid')
        end
      end

      context 'name' do
        before do
          params = { Operations: [{ 'op': 'Replace', 'path': 'name.formatted', 'value': 'new_name' }] }.to_query

          patch scim_api("scim/v2/groups/#{group.full_path}/Users/#{identity.extern_uid}?#{params}")
        end

        it 'responds with 204' do
          expect(response).to have_gitlab_http_status(204)
        end

        it 'updates the name' do
          expect(user.reload.name).to eq('new_name')
        end
      end

      context 'Remove user' do
        before do
          params = { Operations: [{ 'op': 'Replace', 'path': 'active', 'value': 'False' }] }.to_query

          patch scim_api("scim/v2/groups/#{group.full_path}/Users/#{identity.extern_uid}?#{params}")
        end

        it 'responds with 204' do
          expect(response).to have_gitlab_http_status(204)
        end

        it 'removes the identity link' do
          expect { identity.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  describe 'DELETE /scim/v2/groups/:group/Users/:id' do
    context 'existing user' do
      before do
        delete scim_api("scim/v2/groups/#{group.full_path}/Users/#{identity.extern_uid}")
      end

      it 'responds with 204' do
        expect(response).to have_gitlab_http_status(204)
      end

      it 'removes the identity link' do
        expect { identity.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    it 'responds with 404 if there is no user' do
      delete scim_api("scim/v2/groups/#{group.full_path}/Users/123")

      expect(response).to have_gitlab_http_status(404)
    end
  end

  def scim_api(url, token: true)
    api(url, user, version: '', oauth_access_token: token ? scim_token : nil)
  end
end
