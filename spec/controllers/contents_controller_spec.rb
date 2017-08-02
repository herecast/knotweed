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

      subject { put :update, id: @content, continue_editing: true, content: { content_category_id: @cat_2.id, title: 'Luke OG Skywalker' } }

      it "should create a category correction record" do
        subject
        expect(CategoryCorrection.where(content_id: @content.id).count).to eq 1
        @content.reload
        expect(@content.category).to eq @cat_2.name
      end
    end

    context "when category does not change" do

      subject { put :update, id: @content, create_new: true, content: { title: "Fake Title Update" } }

      it "should not create a category correction if category doesn't change" do
        subject
        expect(CategoryCorrection.where(content_id: @content.id).count).to eq 0
      end
    end

    context "when content has_event_calendar" do

      subject { put :update, id: @content.id, has_event_calendar: true, content: { title: "Fake Title Update" }, format: 'json' }

      it "should respond with 200 status code" do
        subject
        @content.reload
        expect(response.code).to eq '200'
        expect(response.body).to eq @content.to_json
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

    context "when no index param" do

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

    context "when index param present" do

      subject { get :edit, { id: @content.id, index: 0 } }

      it "finds next event id" do
        allow(Content).to receive_message_chain(:ransack, :result, :order, :page, :per, :select) { [@content, @next_content] }
        subject
        expect(assigns(:next_content_id)).to eq @next_content.id
      end

      it "jumps to next page if necessary" do
        allow(Content).to receive_message_chain(:ransack, :result, :order, :page, :per, :select) { [@next_content, nil] }
        subject
        expect(assigns(:next_content_id)).to eq @next_content.id
      end
    end

    context "when channel present" do
      before do
        @channel = FactoryGirl.create :channel
      end

      subject { get :edit, id: @content.id }

      it "should respond with a 302 status code" do
        allow_any_instance_of(Content).to receive(:channel).and_return @channel
        allow_any_instance_of(Channel).to receive(:present?).and_return true
        @content.update_attribute(:channel_id, @channel.id)
        @content.update_attribute(:channel_type, 'Event')

        subject

        expect(response.code).to eq '302'
      end
    end
  end

  describe 'new' do
    subject { get :new }

    it 'should respond with 200 status code' do
      subject
      expect(response.code).to eq '200'
    end
  end

  describe 'POST #create' do
    before do
      @image = FactoryGirl.create :image
      allow(Fog::Storage).to receive(:new).and_return('fog')
      allow_any_instance_of(String).to receive(:copy_object)
      allow_any_instance_of(String).to receive(:delete_object)
    end

    let(:content_params) { {
      image_list: "#{@image.id}",
      title: 'Jabba',
      content_category_id: 4,
      category_reviewed: true,
      has_event_calendar: true,
      subtitle: 'subtitle',
      authors: 'Some peeps, like Jabba',
      copyright: 'Tattooine, 2348',
      pubdate: Time.current,
      url: 'http://empire.org',
      banner_ad_override: 34343,
      sanitized_content: 'Propaganda, probably',
      content_locations_attributes: [
        {
          location_type: 'base',
          location_id: FactoryGirl.create(:location).id
        }
      ],
      organization_ids: '12,15',
      similar_content_overrides: '234,235'
    } }

    it "allows specified parameters" do
      should permit(
        :title,
        :content_category_id,
        :organization_id,
        :category_reviewed,
        :has_event_calendar,
        :subtitle,
        :authors,
        :issue_id,
        :parent_id,
        :copyright,
        :pubdate,
        :url,
        :banner_ad_override,
        :sanitized_content,
        content_locations_attributes: [
          :id, :location_type, :location_id, :_destroy
        ],
        organization_ids: [],
        similar_content_overrides: []
      ).for(:create, params: { content: content_params })
    end

    subject { post :create, { content: { image_list: "#{@image.id}", title: 'Jabba' } } }

    context "when content creation succeeds" do
      it "should respond with 302 status code" do
        subject
        expect(flash.now[:notice]).to be_truthy
        expect(response.code).to eq '302'
      end
    end

    context "when content creation fails" do
      it "should render new content page" do
        allow_any_instance_of(Content).to receive(:save).and_return(false)
        expect(subject).to render_template 'new'
      end
    end
  end

  describe 'GET #show' do
    before do
      @content = FactoryGirl.create :content
    end

    subject { get :show, id: @content.id, continue_editing: true }

    it "should respond with 302 status code" do
      subject
      expect(response.code).to eq '302'
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

  describe 'GET #publish' do
    before do
      @repository = FactoryGirl.create :repository
      @content = FactoryGirl.create :content
    end

    context "when publish succeeds" do

      subject { get :publish, id: @content.id, method: 'export_to_xml', repository_id: @repository.id }

      it "should flash success" do
        allow_any_instance_of(Content).to receive(:publish).and_return true
        subject
        expect(flash.now[:notice]).to include 'successful'
        expect(response.code).to eq '302'
      end
    end

    context "when publish fails" do

      subject { get :publish, id: @content.id, method: 'export_to_xml', repository_id: @repository.id}

      it "should flash error" do
        allow_any_instance_of(Content).to receive(:publish).and_return false
        subject
        expect(flash.now[:error]).to include 'error'
        expect(response.code).to eq '302'
      end
    end
  end

  describe 'GET #rdf_to_gate' do
    before do
      @repository = FactoryGirl.create :repository
      @content = FactoryGirl.create :content
    end

    subject { get :rdf_to_gate, id: @content.id, repository_id: @repository.id }

    context "when gate_xml is false" do
      it "renders 'not found' text" do
        allow_any_instance_of(Content).to receive(:rdf_to_gate).and_return false
        subject
        expect(response.body).to include @content.id.to_s
      end
    end

    context "when gate_xml is true" do
      it "renders file" do
        allow_any_instance_of(Content).to receive(:rdf_to_gate).and_return({ "data" => 'fake' })
        subject
        expect(response.headers["Content-Type"]).to eq 'application/xml'
      end
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
