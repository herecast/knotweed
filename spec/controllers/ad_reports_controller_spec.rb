require 'rails_helper'

RSpec.describe AdReportsController, type: :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  describe 'GET #index' do
    subject { get :index }

    it 'returns ok status' do
      subject
      expect(response).to have_http_status :ok
    end
  end

end
