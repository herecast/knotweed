# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqWrapperController, type: :controller do
  let(:admin) { FactoryGirl.create :admin }
  before { sign_in admin }

  describe 'GET #index' do
    subject! { get :index }

    it 'returns ok status' do
      expect(response).to have_http_status :ok
    end
  end
end
