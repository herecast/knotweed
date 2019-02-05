# frozen_string_literal: true

require 'spec_helper'

describe BusinessLocationsController, type: :controller do
  before do
    @user = FactoryGirl.create :admin
    @business_location = FactoryGirl.create :business_location
    sign_in @user
  end

  describe "GET 'index'" do
    it 'returns http success' do
      get 'index'
      expect(response).to be_successful
    end

    context 'when reset' do
      subject { get :index, params: { reset: true } }

      it 'returns all business locations' do
        subject
        expect(assigns(:business_locations).length).to eq BusinessLocation.count
      end
    end

    context 'when query' do
      before do
        FactoryGirl.create :business_location
      end

      let(:query) { { q: 'query' } }

      subject { get :index, params: query }

      it 'returns results' do
        subject
        expect(response).to be_successful
      end
    end
  end

  describe "GET 'new'" do
    subject { get 'new' }

    it 'returns http success' do
      expect(response).to be_successful
    end

    context 'when business_location has organization_id' do
      let(:organization) { FactoryGirl.create :organization }

      subject { get :new, params: { organization_id: organization.id } }

      it 'assigns organization to business location' do
        subject
        expect(assigns(:business_location).organization.id).to eq organization.id
      end
    end

    context 'when xhr request' do
      subject { get :new, xhr: true }

      it 'responds with form' do
        subject
        expect(response).to render_template 'business_locations/partials/_form_js'
      end
    end
  end

  describe 'POST #create' do
    context 'when creation succeeds' do
      it 'html: redirects to business locations' do
        post :create, params: { business_location: { address: 'fake', city: 'fake', state: 'VT' } }
        expect(response.code).to eq '302'
        expect(response).to redirect_to business_locations_path
      end

      it 'js: should respond with 200 status code' do
        post :create, format: 'js', params: { business_location: { address: 'fake', city: 'fake', state: 'VT' } }
        expect(response.code).to eq '200'
      end
    end

    context 'when creation fails' do
      before do
        allow_any_instance_of(BusinessLocation).to receive(:save).and_return false
      end

      it 'html: renders new page' do
        post :create, params: { business_location: { address: 'fake', city: 'fake', state: 'VT' } }
        expect(response).to render_template 'new'
      end

      it 'js: responds with errors' do
        allow_any_instance_of(BusinessLocation).to receive(:errors).and_return ['error']
        post :create, format: :js, params: { business_location: { address: 'fake', city: 'fake', state: 'VT' } }
        expect(JSON.parse(response.body).length).to eq 1
      end
    end
  end

  describe "GET 'edit'" do
    it 'returns http success' do
      get 'edit', params: { id: @business_location.id }
      expect(response).to be_successful
    end

    context 'when nearby locations exist' do
      before do
        @other_location = FactoryGirl.create :business_location
        @event = FactoryGirl.create :event, venue_id: @other_location.id
      end

      subject { get :edit, params: { id: @business_location.id } }

      it 'assigns event count for nearby venues' do
        subject
        expect(assigns(:events_per_venue)[@other_location.id]).to eq 1
      end
    end

    context 'when xhr request' do
      subject { get :edit, xhr: true, params: { id: @business_location.id } }

      it 'responds with form' do
        subject
        expect(response).to render_template 'business_locations/partials/_form_js'
      end
    end
  end

  describe "DELETE 'destroy'" do
    subject { delete :destroy, params: { id: @business_location.id } }

    it 'should remove the business location' do
      expect { subject }.to change{ BusinessLocation.count }.by(-1)
    end

    context 'with a business profile' do
      before { @business_location.update(business_profile: FactoryGirl.create(:business_profile)) }

      it 'should not remove the business location' do
        expect { subject }.not_to change{ BusinessLocation.count }
      end
    end
  end

  describe "PUT 'update'" do
    subject { put :update, params: { id: @business_location.to_param, business_location: params } }

    describe 'with valid params' do
      let(:params) { { name: 'Another string' } }

      it 'updates the requested venue' do
        subject
        @business_location.reload
        expect(@business_location.name).to eq(params[:name])
      end

      it 'redirect to business_locations' do
        subject
        expect(response).to redirect_to(business_locations_path)
      end

      context 'when update fails' do
        before do
          allow_any_instance_of(BusinessLocation).to receive(:update_attributes).and_return false
        end

        context "when html request" do
          it 'renders edit page' do
            subject
            expect(response).to render_template 'edit'
          end
        end

        context "when js request" do
          before do
            @errors = ['bad error']
            allow_any_instance_of(BusinessLocation).to receive(:errors).and_return @errors
          end

          subject { put :update, params: { id: @business_location.id, business_location: params }, format: :js }

          it 'returns errors in json' do
            subject
            expect(JSON.parse(response.body)).to eq({ "business_locations" => @errors })
          end
        end
      end
    end
  end
end
