require 'spec_helper'

describe ContentsController, type: :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  describe "PUT #update" do
    before do
      @content = FactoryGirl.create(:content)
      @cat_2 = FactoryGirl.create :content_category
    end

    context "when category changes" do

      subject { put :update, id: @content, content: { content_category_id: @cat_2.id, title: 'Luke OG Skywalker' } }

      it "should create a category correction record" do
        subject
        expect(CategoryCorrection.where(content_id: @content.id).count).to eq 1
        @content.reload
        expect(@content.category).to eq @cat_2.name
      end
    end

    context "when category does not change" do

      subject { put :update, id: @content, content: { title: "Fake Title Update" } }

      it "should not create a category correction if category doesn't change" do
        subject
        expect(CategoryCorrection.where(content_id: @content.id).count).to eq 0
      end
    end

    context "when update fails" do

      subject { put :update, id: @content, content: { title: "Fake Title Update" } }

      it "should render edit page" do
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

    subject { get :index, reset: true }

    it 'should respond with 200 status code' do
      subject
      expect(response.code).to eq '200'
    end

    context 'with an organization search param' do
      before do
        @org = FactoryGirl.create :organization
        @contents = FactoryGirl.create_list :content, 3, organization: @org
      end

      subject { get :index, q: { organization_id_in: [@org.id], locations_id_in: [''] } }

      it 'should respond with the content belonging to that organization' do
        subject
        expect(assigns(:contents)).to match_array @contents
      end
    end

    describe 'default filtering' do
      let!(:campaign) { FactoryGirl.create(:content, :campaign) }

      it 'should not return campaigns' do
        get :index, q: { organization_id_in: [campaign.organization.id] }
        expect(assigns(:contents)).to_not include(campaign)
      end
    end

    context 'with a location search param' do
      before do
        @location = FactoryGirl.create :location
        @content = FactoryGirl.create :content
        @content.locations << @location
      end

      subject { get :index, q: { locations_id_in: ['', @location.id.to_s] } }

      it "returns contents connected to the location" do
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

    subject { get :edit, id: @content.id }

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

    subject { delete :destroy, id: @content.id, format: 'js' }

    it "should respond with 200 status code" do
      expect{ subject }.to change{ Content.count }.by -1
      expect(response.code).to eq '200'
    end
  end

  describe 'parent_select_options' do
    before do
      @content = FactoryGirl.create :content, title: 'nice title'
    end

    context "when query is raw id search" do

      subject { xhr :get, :parent_select_options, search_query: @content.id.to_s, q: { id_eq: nil }, format: :js }

      it "should respond with 200 status code" do
        subject
        expect(assigns(:contents)).to match_array [ nil, ["nice title", @content.id] ]
        expect(response.code).to eq '200'
      end
    end

    context "when query is id search" do

      subject { xhr :get, :parent_select_options, content_id: @content.id, q: { id_eq: nil }, format: :js }

      it "should respond with 200 status code" do
        subject
        expect(assigns(:orig_content)).to eq @content
        expect(response.code).to eq '200'
      end
    end

    context "when query is a title search" do

        subject { xhr :get, :parent_select_options, search_query: @content.title, q: { id_eq: nil }, format: :js }

        it "should respond with 200 status code" do
          subject
          expect(assigns(:contents)).to match_array [ nil, ["nice title", @content.id] ]
        end
    end
  end

  describe "POST #category_correction" do
    before do
      @content = FactoryGirl.create :content
      @category = FactoryGirl.create :category
    end

    subject { post :category_correction, content_id: @content.id }

    context "when category correction saves" do
      it "responds with confirmation text" do
        allow_any_instance_of(Content).to receive(:category).and_return @category
        subject
        expect(response.code).to eq '200'
        expect(response.body).to include @content.id.to_s
      end
    end

    context "when category correction save fails" do
      it "should respond with 500 status code" do
        allow_any_instance_of(Content).to receive(:category).and_return @category
        allow_any_instance_of(CategoryCorrection).to receive(:save).and_return false
        subject
        expect(response.code).to eq '500'
      end
    end
  end

  describe 'POST #category_correction_reviewed' do
    before do
      @content = FactoryGirl.create :content
    end

    context "when reviewed and saved" do

      subject { post :category_correction_reviwed, content_id: @content.id, checked: 'true' }

      it "responds with confirmation text" do
        subject
        expect(response.code).to eq '200'
        expect(response.body).to include @content.id.to_s
      end
    end

    context "when reviewed but content not saved" do

      subject { post :category_correction_reviwed, content_id: @content.id, checked: 'true' }

      it "should respond with 500 status code" do
        allow_any_instance_of(Content).to receive(:save).and_return false
        subject
        expect(response.code).to eq '500'
      end
    end

    context "when not reviewed and saved" do

      subject { post :category_correction_reviwed, content_id: @content.id, checked: 'false' }

      it "should respond with confirmation text" do
        subject
        expect(response.code).to eq '200'
        expect(response.body).to include @content.id.to_s
      end
    end
  end

end
