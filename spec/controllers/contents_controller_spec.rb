# frozen_string_literal: true

require 'spec_helper'

describe ContentsController, type: :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  describe 'PUT #update' do
    before do
      @content = FactoryGirl.create(:content)
      @cat_2 = FactoryGirl.create :content_category
    end

    context 'when update fails' do
      subject { put :update, params: { id: @content, content: { title: 'Fake Title Update' } } }

      it 'should render edit page' do
        allow_any_instance_of(Content).to receive(:update_attributes).and_return false
        subject
        expect(response).to render_template 'edit'
      end
    end
  end

  describe 'index' do
    before do
      FactoryGirl.create_list :content, 5
    end

    subject { get :index, params: { reset: true } }

    it 'should respond with 200 status code' do
      subject
      expect(response.code).to eq '200'
    end

    context 'with an organization search param' do
      before do
        @org = FactoryGirl.create :organization
        @contents = FactoryGirl.create_list :content, 3, organization: @org
      end

      subject { get :index, params: { q: { organization_id_in: [@org.id], locations_id_eq: '' } } }

      it 'should respond with the content belonging to that organization' do
        subject
        expect(assigns(:contents)).to match_array @contents
      end
    end

    describe 'default filtering' do
      let!(:campaign) { FactoryGirl.create(:content, :campaign) }

      it 'should not return campaigns' do
        get :index, params: { q: { organization_id_in: [campaign.organization.id] } }
        expect(assigns(:contents)).to_not include(campaign)
      end
    end

    context 'with a location search param' do
      before do
        @location = FactoryGirl.create :location
        @content = FactoryGirl.create :content,
                                      location_id: @location.id
      end

      subject { get :index, params: { q: { location_id_eq: @location.id.to_s } } }

      it 'returns contents connected to the location' do
        subject
        expect(assigns(:contents)).to match_array [@content]
      end
    end
  end

  describe 'GET #edit' do
    before do
      @content = FactoryGirl.create :content
      @next_content = FactoryGirl.create :content
    end

    subject { get :edit, params: { id: @content.id } }

    it 'should respond with 200 status code' do
      subject
      expect(response.code).to eq '200'
    end

    it 'should appropriately load the content' do
      subject
      expect(assigns(:content)).to eq @content
    end
  end

  describe 'DELETE #destroy' do
    before do
      @content = FactoryGirl.create :content
    end

    subject { delete :destroy, params: { id: @content.id }, format: 'js' }

    it 'should respond with 200 status code' do
      expect { subject }.to change { Content.count }.by -1
      expect(response.code).to eq '200'
    end
  end

  describe 'parent_select_options' do
    before do
      @content = FactoryGirl.create :content, title: 'nice title'
    end

    context 'when query is raw id search' do
      subject { get :parent_select_options, xhr: true, params: { search_query: @content.id.to_s, q: { id_eq: nil } }, format: :js }

      it 'should respond with 200 status code' do
        subject
        expect(assigns(:contents)).to match_array [nil, ['nice title', @content.id]]
        expect(response.code).to eq '200'
      end
    end

    context 'when query is id search' do
      subject { get :parent_select_options, xhr: true, params: { content_id: @content.id, q: { id_eq: nil } }, format: :js }

      it 'should respond with 200 status code' do
        subject
        expect(assigns(:orig_content)).to eq @content
        expect(response.code).to eq '200'
      end
    end

    context 'when query is a title search' do
      subject { get :parent_select_options, xhr: true, params: { search_query: @content.title, q: { id_eq: nil } }, format: :js }

      it 'should respond with 200 status code' do
        subject
        expect(assigns(:contents)).to match_array [nil, ['nice title', @content.id]]
      end
    end
  end
end
