require 'spec_helper'

describe CategoryCorrection do
  describe "after_create" do
    it "should update the category of the corresponding content and save the contents body" do
      c = FactoryGirl.create(:content)
      cat_cor = FactoryGirl.create(:category_correction, content: c)
      c = Content.find c.id
      c.categories.should == cat_cor.new_category
      cat_cor.content_body.should == c.content
      cat_cor.title.should == c.title
    end
  end
end
