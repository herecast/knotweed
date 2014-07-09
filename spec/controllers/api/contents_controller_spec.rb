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

    it "should exclude contents not in the specified repo" do
      c2 = FactoryGirl.create(:content, parent: @content) # not in the repo
      subject
      response.body.should == JSON.generate([[@content.id, 0]])
    end
  end

end
