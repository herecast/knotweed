require 'spec_helper'

describe UsersController, :type => :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
    request.env['HTTP_REFERER'] = 'where_i_came_from'
  end

  describe 'GET show' do
    before { @user = FactoryGirl.create :user }
    subject! { get :show, id: @user.id }

    it 'should respond with a 200 status' do
      expect(response.code).to eq '200'
    end

    it 'should load the user' do
      expect(assigns(:user)).to eq @user
    end
  end

  describe 'GET new' do
    subject! { get :new }

    it 'should respond with a 200 status' do
      expect(response.code).to eq '200'
    end
  end

  describe 'GET #edit' do

    subject { get :edit, id: @user.id }

    it "renders edit page" do
      subject
      expect(assigns(:user)).to be_a User
      expect(response).to have_http_status 200
    end
  end

  describe 'GET index' do
    it 'returns http success' do
      get 'index'
      expect(response).to be_success
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

  describe "PUT #update" do

    context "when successful update of managed organization" do
      before do
        @organization = FactoryGirl.create :organization
      end

      subject { put :update, id: @user.id, user: { name: 'bill', managed_organization_id: @organization.id } }

      it "redirects to user" do
        subject
        expect(response.code).to eq '302'
      end
    end

    context "when successful update" do

      subject { put :update, id: @user.id, user: { name: 'bill' } }

      it "redirects to user" do
        allow_any_instance_of(User).to receive(:update_attributes).and_return true
        subject
        expect(response.code).to eq '302'
      end
    end

    context "when unsuccessful save" do

      subject { put :update, id: @user.id, user: { name: 'bill' } }

      it "redirects to user" do
        allow_any_instance_of(User).to receive(:update_attributes).and_return false
        subject
        expect(response.code).to eq '302'
      end
    end
  end

  describe "DELETE #destroy" do

    context "when admin deletes another user" do
      before do
        @new_user = FactoryGirl.create :user, email: 'tessek@squidhead.com'
      end

      subject { delete :destroy, id: @new_user.id }

      it "deletes the user" do
        expect{ subject }.to change{ User.count }.by -1
        expect(response.code).to eq '302'
      end
    end

    context "when admin tries to delete self" do

      subject { delete :destroy, id: @user.id }

      it "rejects delete request" do
        subject
        expect(User.count).to eq 1
        expect(response.code).to eq '302'
      end
    end
  end

  describe "POST #create" do
    before do
      @role = FactoryGirl.create :role
    end

    subject { post :create, user: { name: 'Ya boi Tessek', email: 'tessek@squidhead.com', password: '12345678', password_confirmation: '12345678', location_id: '1', @role.name => 'on' } }

    context "when creation succeeds" do
      it "redirects to user path" do
        expect{ subject }.to change{ User.count }.by 1
        expect(response.code).to eq '302'
      end
    end

    context "when creation fails" do
      it "renders new page" do
        allow_any_instance_of(User).to receive(:save!).and_return false
        subject
        expect(response).to render_template 'new'
      end
    end
  end

end
