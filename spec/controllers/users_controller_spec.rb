# frozen_string_literal: true

require 'spec_helper'

describe UsersController, type: :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
    request.env['HTTP_REFERER'] = 'where_i_came_from'
  end

  describe 'GET show' do
    before { @user = FactoryGirl.create :user }
    subject! { get :show, params: { id: @user.id } }

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
    subject { get :edit, params: { id: @user.id } }

    it 'renders edit page' do
      subject
      expect(assigns(:user)).to be_a User
      expect(response).to have_http_status 200
    end
  end

  describe 'GET index' do
    it 'returns http success' do
      get 'index'
      expect(response).to be_successful
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
          get 'index', params: { page: 2 }
          expect(assigns(:users)).to_not include User.first
        end
      end
    end

    context 'with search parameters' do
      context 'when there are matches' do
        before do
          @user_1 = FactoryGirl.create :user, name: 'Nick P'
          @user_2 = FactoryGirl.create :user, name: 'Nick G'
        end

        context 'when admin searches by id' do
          subject { get :index, params: { q: { id_eq: @user_1.id } } }

          it 'returns matching user' do
            subject
            expect(assigns(:users)).to match_array [@user_1]
          end
        end

        context 'when admin searches by email' do
          subject { get :index, params: { q: { email_eq: @user_2.email } } }

          it 'returns matching user' do
            subject
            expect(assigns(:users)).to match_array [@user_2]
          end
        end

        context 'when admin searches by name' do
          subject { get :index, params: { q: { name_cont: 'nick' } } }

          it 'returns matching users' do
            subject
            expect(assigns(:users)).to match_array [@user_1, @user_2]
          end
        end

        context 'when search by roles' do
          before do
            @role = FactoryGirl.create :role, name: 'jedi'
            @user_1.roles << @role
          end

          subject { get :index, params: { q: { roles: { @role.name => 'on' } } } }

          it 'returns Users with selected Role' do
            subject
            expect(assigns(:users)).to match_array [@user_1]
          end
        end

        context 'when admin searches for Social Login' do
          before do
            SocialLogin.create(user_id: @user_1.id, provider: 'facebook',
                               uid: 1234)
          end

          subject { get :index, params: { q: { social_login: 1 } } }

          it 'returns users with a social login' do
            subject
            expect(assigns(:users)).to match_array [@user_1]
          end
        end
      end

      context 'when admin search finds no matches' do
        subject { get :index, params: { q: { name_cont: 'xyz' } } }

        it 'returns empty array' do
          subject
          expect(assigns(:users)).to eq []
        end
      end

      context 'when reset' do
        subject { get :index, params: { reset: true } }

        it 'returns all users' do
          subject
          expect(assigns(:users).length).to eq User.count
        end
      end
    end
  end

  describe 'PUT #update' do
    context 'when successful update' do
      before do
        @location = FactoryGirl.create :location
      end

      subject { put :update, params: { id: @user.id, user: { name: 'bill', location_id: @location.id } } }

      it 'redirects to user' do
        allow_any_instance_of(User).to receive(:update_attributes).and_return true
        subject
        expect(response.code).to eq '302'
      end

      it 'allows receive_comment_alerts to be updated' do
        put :update, params: { id: @user.id, user: { receive_comment_alerts: false } }
        @user.reload
        expect(@user.receive_comment_alerts).to eq false
      end
    end

    context 'when unsuccessful save' do
      subject { put :update, params: { id: @user.id, user: { name: 'bill' } } }

      it 'renders edit' do
        allow_any_instance_of(User).to receive(:update_attributes).and_return false
        subject
        expect(response).to render_template('users/edit')
      end
    end

    context 'when updating email' do
      let(:new_email) { 'new@email.com' }
      subject { put :update, params: { id: @user.id, user: { email: new_email } } }

      it 'does not require confirmation' do
        subject
        @user.reload

        expect(@user.email).to eql new_email
        expect(@user.unconfirmed_email).to be_blank
      end
    end

    context 'when updating user roles' do
      before do
        @role_name = 'Sick role'
        FactoryGirl.create :role, name: @role_name
      end

      subject { put :update, params: { id: @user.id, user: { roles: { @role_name => 'on' } } } }

      it 'updates user role' do
        expect { subject }.to change {
          @user.has_role?(@role_name)
        }.to true
      end
    end
  end

  describe 'PUT #update_subscription' do
    context 'when creating a new subscription for a user' do
      before do
        @listserv = FactoryGirl.create :listserv
      end
      subject { put :update_subscription, xhr: true, params: { id: @user.id, user_id: @user.id, listserv_id: @listserv.id } }

      it 'creates a subscription to the listserv for the user' do
        expect { subject }.to change { @user.subscriptions.reload.count }.by 1
      end

      it 'runs SubscribeToListservSilently' do
        expect(SubscribeToListservSilently).to receive(:call).with(@listserv, @user, request.remote_ip)
        subject
      end
    end

    context 'when unsubscribing a user from a current subscription' do
      before do
        @listserv = FactoryGirl.create :listserv
        @subscription = FactoryGirl.create :subscription, user_id: @user.id, listserv_id: @listserv.id
      end
      subject { put :update_subscription, xhr: true, params: { id: @user.id, user_id: @user.id, listserv_id: @listserv.id } }

      it 'updates the subscription' do
        subject
        expect(@subscription.reload.unsubscribed_at).to_not be_nil
      end

      it 'runs the Unsubscribe Job' do
        expect(UnsubscribeSubscription).to receive(:call).with(@subscription)
        subject
      end
    end

    context 'when re-subscribing a user to a listserv' do
      before do
        @listserv = FactoryGirl.create :listserv
      end
      subject { put :update_subscription, xhr: true, params: { id: @user.id, user_id: @user.id, listserv_id: @listserv.id } }

      it 'sets unsubscribed_at to nil' do
        subject
        @subscription = Subscription.where(listserv_id: @listserv.id, user_id: @user.id).first
        expect(@subscription.unsubscribed_at).to be_nil
      end

      it 'runs SubscribeToListservSilently' do
        expect(SubscribeToListservSilently).to receive(:call).with(@listserv, @user, request.remote_ip)
        subject
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when admin deletes another user' do
      before do
        @new_user = FactoryGirl.create :user, email: 'tessek@squidhead.com'
      end

      subject { delete :destroy, params: { id: @new_user.id } }

      it 'deletes the user' do
        expect { subject }.to change { User.count }.by -1
        expect(response.code).to eq '302'
      end
    end

    context 'when admin tries to delete self' do
      subject { delete :destroy, params: { id: @user.id } }

      it 'rejects delete request' do
        subject
        expect(User.count).to eq 1
        expect(response.code).to eq '302'
      end
    end
  end

  describe 'POST #create' do
    before do
      @role = FactoryGirl.create :role
      @location = FactoryGirl.create :location
    end

    let(:params) { {
      user: {
        name: 'Ya boi Tessek',
        email: 'tessek@squidhead.com',
        password: '12345678',
        password_confirmation: '12345678',
        location_id: @location.id,
        @role.name => 'on',
        handle: 'tessek'
      }
    } }

    subject { post :create, params: params }

    context 'when creation succeeds' do
      it 'redirects to user path' do
        expect { subject }.to change { User.count }.by 1
        expect(response.code).to eq '302'
      end
    end

    context 'when creation fails' do
      it 'renders new page' do
        allow_any_instance_of(User).to receive(:save!).and_return false
        post :create, params: { user: { name: 'Invalid User' } }
        expect(response).to render_template 'new'
      end
    end
  end
end
