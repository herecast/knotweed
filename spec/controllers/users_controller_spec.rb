require 'spec_helper'

describe UsersController do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  describe 'GET index' do
    before { @users = FactoryGirl.create_list :user, 3 }
    subject! { get :index }

    it 'should respond with a 200 status' do
      response.code.should eq '200'
    end

    it 'should load the users' do
      assigns(:users).should eq User.all
    end
  end

  describe 'GET show' do
    before { @user = FactoryGirl.create :user }
    subject! { get :show, id: @user.id }

    it 'should respond with a 200 status' do
      response.code.should eq '200'
    end

    it 'should load the user' do
      assigns(:user).should eq @user
    end
  end

  describe 'GET new' do
    subject! { get :new }

    it 'should respond with a 200 status' do
      response.code.should eq '200'
    end
  end
end
