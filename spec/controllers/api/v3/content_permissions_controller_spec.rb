# frozen_string_literal: true

require 'spec_helper'

describe Api::V3::ContentPermissionsController, type: :controller do
  describe 'GET index' do
    let(:contents) { FactoryGirl.create_list :content, 3 }
    let(:user) { FactoryGirl.create :user }
    before { api_authenticate user: user }

    subject! { get :index, params: { content_ids: contents.map(&:id) } }

    it 'should respond with 200' do
      expect(response).to have_http_status :ok
    end
  end
end
