require 'spec_helper'

describe ContentsController, :type => :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end
  describe "UPDATE" do
    before do
      @content = FactoryGirl.create(:content)
    end

    it "should create a category correction record if category changes" do
      cat_2 = FactoryGirl.create :content_category
      put :update, id: @content, content: { content_category_id: cat_2.id }
      expect(CategoryCorrection.where(content_id: @content.id).count).to eq(1)
      @content.reload
      expect(@content.category).to eq(cat_2.name)
    end

    it "should not create a category correction if category doesn't change" do
      put :update, id: @content, content: { title: "Fake Title Update" }
      expect(CategoryCorrection.where(content_id: @content.id).count).to eq(0)
    end
  end

  describe 'index' do
    before do
      FactoryGirl.create_list :content, 5
    end

    subject { get :index }

    it 'should respond with 200 status code' do
      subject
      expect(response.code).to eq '200'
    end

    context 'with an organization search param' do
      before do
        @org = FactoryGirl.create :organization
        @contents = FactoryGirl.create_list :content, 3, organization: @org
      end

      subject { get :index, q: { organization_id_in: [@org.id] } }

      it 'should respond with the content belonging to that organization' do
        subject
        expect(assigns(:contents)).to match_array @contents
      end
    end
  end

  describe 'edit' do
    before do
      @content = FactoryGirl.create :content
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

  describe 'new' do
    subject { get :new }

    it 'should respond with 200 status code' do
      subject
      expect(response.code).to eq '200'
    end
  end

end
