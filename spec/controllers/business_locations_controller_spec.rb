require 'spec_helper'

describe BusinessLocationsController, :type => :controller do
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

      it "returns no business locations" do
        allow_any_instance_of(Ransack::Search).to receive_message_chain(:result, :page, :per).and_return []
        subject
        expect(assigns(:business_locations)).to eq []
      end
    end

    context 'when query' do
      let(:query) { { q: 'query' } }
      let(:results) { [FactoryGirl.build_stubbed(:business_location)] }

      subject { get :index, params: query }

      it "returns results" do
        Ransack::Search.any_instance.stub_chain(:result, :page, :per) { results }
        subject
        expect(assigns(:business_locations)).to eq results
      end
    end
  end

  describe "GET 'new'" do
    it 'returns http success' do
      get 'new'
      expect(response).to be_successful
    end

    context "when business_location has organization_id" do
      let(:organization) { FactoryGirl.create :organization }

      subject { get :new, params: { organization_id: organization.id } }

      it "assigns organization to business location" do
        subject
        expect(assigns(:business_location).organization.id).to eq organization.id
      end
    end

    context "when xhr request" do

      subject { get :new, xhr: true }

      it "responds with form" do
        subject
        expect(response).to render_template 'business_locations/partials/_form_js'
      end
    end
  end

  describe "POST #create" do

    context "when creation succeeds" do
      it "html: redirects to business locations" do
        post :create, params: { business_location: { address: 'fake', city: 'fake', state: 'VT' } }
        expect(response.code).to eq '302'
        expect(response).to redirect_to business_locations_path
      end

      it "js: should respond with 200 status code" do
        post :create, format: 'js', params: { business_location: { address: 'fake', city: 'fake', state: 'VT' } }
        expect(response.code).to eq '200'
      end
    end

    context "when creation fails" do
      before do
        allow_any_instance_of(BusinessLocation).to receive(:save).and_return false
      end

      it "html: renders new page" do
        post :create, params: { business_location: { address: 'fake', city: 'fake', state: 'VT' } }
        expect(response).to render_template 'new'
      end

      it "js: responds with errors" do
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

    context "when nearby locations exist" do
      before do
        @other_location = FactoryGirl.create :business_location
        allow_any_instance_of(BusinessLocation).to receive(:nearbys).and_return [@other_location]
        @event = FactoryGirl.create :event, venue_id: @other_location.id
      end

      subject { get :edit, params: { id: @business_location.id } }

      it "assigns event count for nearby venues" do
        subject
        expect(assigns(:events_per_venue)[@other_location.id]).to eq 1
      end
    end

    context "when xhr request" do

      subject { get :edit, xhr: true, params: { id: @business_location.id } }

      it "responds with form" do
        subject
        expect(response).to render_template 'business_locations/partials/_form_js'
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

      context "when update fails" do
        before do
          allow_any_instance_of(BusinessLocation).to receive(:update_attributes).and_return false
        end

        it "html: renders edit page" do
          subject
          expect(response).to render_template 'edit'
        end

        it "js: re" do
          allow_any_instance_of(BusinessLocation).to receive(:errors).and_return ['error']
          put :update, params: { id: @business_location.id, business_location: params }, format: :js
          expect(JSON.parse(response.body).length).to eq 1
        end
      end
    end
  end
end
