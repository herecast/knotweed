# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ListservsController, type: :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  let(:valid_attributes) do
    {
      name: 'listserv1',
      list_type: 'internal_digest',
      subscribe_email: 'subscribe@example.org',
      unsubscribe_email: 'unsubscribe@example.org',
      post_email: 'post@example.org',
      digest_send_time: '13:01',
      mc_list_id: 'xyz123',
      mc_group_name: 'xyz123',
      send_digest: false,
      digest_reply_to: 'test@example.org',
      digest_header: '',
      digest_footer: '',
      digest_subject: 'da subject',
      digest_preheader: 'a distinguished curated list',
      sender_name: 'Mace Windu',
      admin_email: 'admin@gmail.com',
      forwarding_email: 'forwarding@mail.com',
      forward_for_processing: '1',
      post_threshold: 5,
      active: true
    }
  end

  describe 'GET #index' do
    it 'assigns all listservs as @listservs' do
      listserv = Listserv.create! valid_attributes
      get :index
      expect(assigns(:listservs)).to eq([listserv])
    end

    context 'with reset param' do
      subject { get :index, params: { reset: true } }

      it 'should reset the search session' do
        expect { subject }.to change { request.session['listservs_search'] }.to(active_true: true)
      end
    end

    context 'with search params' do
      let(:search_params) { { 'fake_search' => 'whatever' } }
      subject { get :index, params: { q: search_params } }

      it 'should set the search session' do
        expect { subject }.to change { request.session['listservs_search'] }.to(search_params)
      end
    end
  end

  describe 'GET #show' do
    it 'assigns the requested listserv as @listserv' do
      listserv = Listserv.create! valid_attributes
      get :show, params: { id: listserv.to_param }
      expect(assigns(:listserv)).to eq(listserv)
    end
  end

  describe 'GET #new' do
    it 'assigns a new listserv as @listserv' do
      get :new
      expect(assigns(:listserv)).to be_a_new(Listserv)
    end
  end

  describe 'GET #edit' do
    it 'assigns the requested listserv as @listserv' do
      listserv = Listserv.create! valid_attributes
      get :edit, params: { id: listserv.to_param }
      expect(assigns(:listserv)).to eq(listserv)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new Listserv' do
        expect do
          post :create, params: { listserv: valid_attributes }
        end.to change(Listserv, :count).by(1)
      end

      it 'assigns a newly created listserv as @listserv' do
        post :create, params: { listserv: valid_attributes }
        expect(assigns(:listserv)).to be_a(Listserv)
        expect(assigns(:listserv)).to be_persisted
      end

      it 'redirects to listserv index' do
        post :create, params: { listserv: valid_attributes }
        expect(response).to redirect_to(listservs_path)
      end
    end

    context 'with invalid listserv' do
      before { allow_any_instance_of(Listserv).to receive(:valid?).and_return(false) }
      subject { post :create, params: { listserv: valid_attributes } }

      it 'should render `new`' do
        subject
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let(:new_attributes) do
        {
          name: 'new name'
        }
      end

      it 'updates the requested listserv' do
        listserv = Listserv.create! valid_attributes
        put :update, params: { id: listserv.to_param, listserv: new_attributes }
        listserv.reload
        expect(listserv.name).to eql 'new name'
      end

      it 'assigns the requested listserv as @listserv' do
        listserv = Listserv.create! valid_attributes
        put :update, params: { id: listserv.to_param, listserv: valid_attributes }
        expect(assigns(:listserv)).to eq(listserv)
      end

      it 'redirects to the listserv' do
        listserv = Listserv.create! valid_attributes
        put :update, params: { id: listserv.to_param, listserv: valid_attributes }
        expect(response).to redirect_to(listservs_url)
      end
    end

    context 'with invalid listserv' do
      let(:listserv) { FactoryGirl.create :listserv }
      before { allow_any_instance_of(Listserv).to receive(:update).and_return(false) }
      subject { put :update, params: { id: listserv.to_param, listserv: { name: 'new_name' } } }

      it 'should render `edit`' do
        subject
        expect(response).to render_template(:edit)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested listserv' do
      listserv = Listserv.create! valid_attributes
      expect do
        delete :destroy, params: { id: listserv.to_param }
      end.to change(Listserv, :count).by(-1)
    end

    it 'redirects to the listservs list' do
      listserv = Listserv.create! valid_attributes
      delete :destroy, params: { id: listserv.to_param }
      expect(response).to redirect_to(listservs_url)
    end
  end
end
