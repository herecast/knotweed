require 'spec_helper'

describe DashboardController do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  describe 'index' do
    subject { get :index }

    it 'should respond with 200 status code' do
      subject
      response.code.should eq '200'
    end
  end
end
