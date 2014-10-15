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

end
