require 'spec_helper'

describe DashboardController, :type => :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  describe 'GET index' do
    subject { get :index }

    it 'should respond with 200 status code' do
      subject
      expect(response.code).to eq '200'
    end
  end
end
