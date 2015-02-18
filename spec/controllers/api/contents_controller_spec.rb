require 'spec_helper'

describe Api::ContentsController do

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

    describe "talk_of_the_town hack" do

      before do
        @tot = FactoryGirl.create(:content_category, name: "talk_of_the_town")
        @pub1 = FactoryGirl.create :publication
        @pub2 = FactoryGirl.create :publication
        FactoryGirl.create_list(:content, 2, source: @pub1)
        FactoryGirl.create_list(:content, 3, source: @pub2)
        @tot_content = FactoryGirl.create(:content, source: @pub1, content_category: @tot)
        @tot_content_2 = FactoryGirl.create(:content, source: @pub2, content_category: @tot)
      end

      describe "when home list is provided" do

        it "should only return talk_of_the_town contents belonging to home_list" do
          query_params = { home_list: @pub1.name, categories: ContentCategory.all.map{ |cc| cc.name }, events: false,
          publications: Publication.all.map{ |p| p.name } }
          get :index, query_params.merge({format: :json})
          assigns(:contents).include?(@tot_content).should == true
          assigns(:contents).include?(@tot_content_2).should == false
          assigns(:contents).include?(@pub2.contents.where("content_category_id != ?", @tot.id).first).should == true
        end

        describe "if user is an admin" do
          it "should return all talk_of_the_town not just home_list" do
            query_params = { home_list: @pub1.name, categories: ContentCategory.all.map{ |cc| cc.name }, events: false,
              publications: Publication.all.map{ |p| p.name }, admin: "true" }
            get :index, query_params.merge({format: :json})
            assigns(:contents).include?(@tot_content).should == true
            assigns(:contents).include?(@tot_content_2).should == true
          end
        end

      end
    end

    describe "if consumer app is specified" do
      before do
        @pub1 = FactoryGirl.create :publication
        @pub2 = FactoryGirl.create :publication
        @pub3 = FactoryGirl.create :publication
        @consumer_app = FactoryGirl.create :consumer_app
        @consumer_app.publications << @pub1 << @pub3
        FactoryGirl.create_list :content, 1, source: @pub1
        FactoryGirl.create_list :content, 1, source: @pub3
        FactoryGirl.create_list :content, 3, source: @pub2
      end

      it "should filter results based on consumer_app.publications" do
        get :index, format: :json, consumer_app_uri: @consumer_app.uri, events: false
        assigns(:contents).count.should == 2
      end

      describe "and publication is specified" do

        it "should filter by consumer_app.publications AND specified publications" do
          get :index, format: :json, consumer_app_uri: @consumer_app.uri, events: false,
            publications: [@pub1.name]
          assigns(:contents).count.should == 1
        end
      end

    end

  end

end
