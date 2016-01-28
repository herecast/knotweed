require 'spec_helper'

describe UsersController do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
    request.env['HTTP_REFERER'] = 'where_i_came_from'
  end

  describe 'GET index' do
    it 'returns http success' do
      get 'index'
      response.should be_success
    end

    context 'pagination' do
      let(:default_per_page) { Kaminari.config.default_per_page }

      before do 
        FactoryGirl.create_list(:user, default_per_page + 1)
      end


      it 'returns {default_per_page} max users' do
        get 'index'
        expect(assigns(:users).size).to be <= default_per_page
      end

      context 'given the page parameter of 2' do
        it 'returns the next page of users' do
          get 'index', {page: 2}
          expect(assigns(:users)).to_not include User.first
        end
      end

      context 'given a limit parameter' do 
        it 'returns max {limit} users' do
          limit = 25
          get 'index', {limit: limit}
          expect(assigns(:users).size).to be <= limit
        end
      end
    end
  end
end
