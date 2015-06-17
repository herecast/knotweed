require 'spec_helper'

describe Api::V1::ContentsController do

  describe 'GET banner' do
    before do
      @content = FactoryGirl.create(:content)
      @promoted_content = FactoryGirl.create(:content)
      @repo = FactoryGirl.create :repository
      @promotion = FactoryGirl.create :promotion, content: @promoted_content
      @pb = FactoryGirl.create :promotion_banner, promotion: @promotion
      Content.any_instance.stub(:get_related_promotion).with(@repo).and_return(@promoted_content.id)
    end

    subject { get :banner, id: @content.id, repository: @repo.dsp_endpoint }

    it 'should assign the appropriate promo instance variable' do
      subject
      assigns(:banner).should eq(@pb)
    end

    it 'should increment the impression count of the banner' do
      count = @pb.impression_count
      subject
      @pb.reload.impression_count.should eq(count+1)
    end

    describe 'with an expired banner' do
      before do
        PromotionBanner.stub(:remove_promotion).with(@repo, @promoted_content.id)
      end
      it 'should render an empty response' do
        @pb.update_attribute :campaign_end, 5.minutes.ago
        subject
        assigns(:banner).should eq(nil)
      end
    end

  end

  describe "GET get_tree" do
    before do
      @content = FactoryGirl.create(:content)
      @repo = FactoryGirl.create(:repository)
      @repo.contents << @content
    end
    
    subject { get :get_tree, id: @content, repository: @repo.dsp_endpoint }

    it "has a 200 status code" do
      subject
      response.code.should eq("200")
    end

    it "responds with a JSON thread of content_id and tier" do
      subject
      response.body.should == JSON.generate([[@content.id, 0]])
    end

    # this piece of functionality was requested to be removed
    # but I expect it might come back, so just commenting for now (NG)
    #
    #it "should exclude contents not in the specified repo" do
    #  c2 = FactoryGirl.create(:content, parent: @content) # not in the repo
    #  subject
    #  response.body.should == JSON.generate([[@content.id, 0]])
    #end
  end

  describe "UPDATE" do
    before do
      @content = FactoryGirl.create(:content, category_reviewed: false)
    end

    subject { put :update, format: :json, id: @content, content: { category_reviewed: 1 } }

    it "has a 200 status code" do
      subject
      response.code.should eq('200')
    end

    it "updates the content with the new attribute" do
      subject
      @content.reload
      @content.category_reviewed.should == true
    end

    it "creates a new dummy category_correction" do
      subject
      cat_cor = CategoryCorrection.last
      cat_cor.content.should == @content
      cat_cor.new_category.should == @content.category
      cat_cor.old_category.should == @content.category
    end
  end

  describe "GET index" do

    it "has a 200 status code" do
      get :index, format: :json
      response.code.should eq('200')
    end

    describe "if consumer app is specified" do
      before do
        @pub1 = FactoryGirl.create :publication
        @pub2 = FactoryGirl.create :publication
        @pub3 = FactoryGirl.create :publication
        @consumer_app = FactoryGirl.create :consumer_app
        @consumer_app.publications << @pub1 << @pub3
        FactoryGirl.create_list :content, 1, publication: @pub1
        FactoryGirl.create_list :content, 1, publication: @pub3
        FactoryGirl.create_list :content, 3, publication: @pub2
      end

      it "should filter results based on consumer_app.publications" do
        get :index, format: :json, consumer_app_uri: @consumer_app.uri, events: false
        assigns(:contents).count.should == 2
      end

      describe "and publication is specified" do

        it "should filter by consumer_app.publications AND specified publications" do
          get :index, format: :json, consumer_app_uri: @consumer_app.uri, events: false,
            publication_ids: [@pub1.id]
          assigns(:contents).count.should == 1
        end
      end

    end

  end

end
