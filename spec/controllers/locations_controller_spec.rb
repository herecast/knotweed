require 'spec_helper'

describe LocationsController, :type => :controller do
  before do
    @user = FactoryGirl.create :admin
    @location = FactoryGirl.create :location
    sign_in @user
    request.env['HTTP_REFERER'] = 'where_i_came_from'
  end

  describe "GET 'index'" do
    it 'returns http success' do
      get 'index'
      expect(response).to be_successful
    end

    context 'when reset' do
      subject { get :index, params: { reset: true } }

      it "returns no locations" do
        allow_any_instance_of(Ransack::Search).to receive_message_chain(:result, :page, :per).and_return []
        subject
        expect(assigns(:locations)).to eq []
      end
    end

    context 'when query' do
      let(:query) { { q: 'query' } }
      let(:results) { [FactoryGirl.build_stubbed(:location)] }

      subject { get :index, params: query }

      it "returns results" do
        Ransack::Search.any_instance.stub_chain(:result, :page, :per) { results }
        subject
        expect(assigns(:locations)).to eq results
      end
    end
  end

  describe "GET 'new'" do
    before do
      get 'new'
    end

    it 'returns http success' do
      expect(response).to be_successful
    end

    it 'renders the new template' do
      expect(response).to render_template 'locations/new'
    end
  end

  describe "POST #create" do
    context "when creation succeeds" do
      it "html: redirects to locations" do
        post :create, params: { location: { city: 'fake', state: 'VT' } }
        expect(response.code).to eq '302'
        expect(response).to redirect_to locations_path
      end
    end

    context "when creation fails" do
      before do
        allow_any_instance_of(Location).to receive(:save).and_return false
      end

      it "html: renders new page" do
        post :create, params: { location: { city: 'fake', state: 'VT' } }
        expect(response).to render_template 'new'
      end
    end
  end

  describe "GET 'edit'" do
    before do
      get 'edit', params: { id: @location.id }
    end

    it 'returns http success' do
      expect(response).to be_successful
    end

    it 'renders the edit template' do
      expect(response).to render_template 'locations/edit'
    end
  end

  describe "PUT 'update'" do
    subject { put :update, params: { id: @location.to_param, location: params } }

    describe 'with valid params' do
      let(:params) { { city: 'Another string' } }

      it 'updates the location' do
        subject
        @location.reload
        expect(@location.city).to eq(params[:city])
      end

      it 'redirect to locations' do
        subject
        expect(response).to redirect_to(locations_path)
      end

      context "when update fails" do
        before do
          allow_any_instance_of(Location).to receive(:update_attributes).and_return false
        end

        it "html: renders edit page" do
          subject
          expect(response).to render_template 'edit'
        end
      end
    end
  end
end
