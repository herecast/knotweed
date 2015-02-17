require 'spec_helper'

describe ContentsController do
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
      CategoryCorrection.where(content_id: @content.id).count.should == 1
      @content.reload
      @content.category.should == cat_2.name
    end

    it "should not create a category correction if category doesn't change" do
      put :update, id: @content, content: { title: "Fake Title Update" }
      CategoryCorrection.where(content_id: @content.id).count.should == 0
    end
  end

end
