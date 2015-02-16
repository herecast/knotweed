require 'spec_helper'

describe Event do
  before do
    @content = FactoryGirl.create :content
    @event = FactoryGirl.create :event, content: @content
  end

  describe "method missing override" do
    it "should allow access to content attributes directly" do
      @event.title.should eq(@content.title)
      @event.authors.should eq(@content.authors)
      @event.pubdate.should eq(@content.pubdate)
    end

    it "should retain normal method_missing behavior if not a content attribute" do
      expect { @event.asdfdas }.to raise_error(NoMethodError)
    end
  end

  describe "description" do
    it "should return content.content" do
      @event.description.should eq(@content.content)
    end
  end

end
