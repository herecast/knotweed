require 'spec_helper'

describe Comment do
  before do
    @content = FactoryGirl.create :content
    @comment = FactoryGirl.create :comment, content: @content
  end

  describe "method missing override" do
    it "should allow access to content attributes directly" do
      @comment.title.should eq(@content.title)
      @comment.authors.should eq(@content.authors)
      @comment.pubdate.should eq(@content.pubdate)
    end

    it "should retain normal method_missing behavior if not a content attribute" do
      expect { @comment.asdfdas }.to raise_error(NoMethodError)
    end
  end

  describe "after_save" do
    it "should also save the associated content record" do
      @content.title = "Changed Title"
      @comment.save # should trigger @content.save callback
      @content.reload.title.should eq "Changed Title"
    end
  end
end
