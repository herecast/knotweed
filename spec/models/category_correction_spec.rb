# == Schema Information
#
# Table name: category_corrections
#
#  id           :integer          not null, primary key
#  content_id   :integer
#  old_category :string(255)
#  new_category :string(255)
#  user_email   :string(255)
#  title        :string(255)
#  content_body :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require 'spec_helper'

describe CategoryCorrection do
  describe "after_create" do
    it "should update the category of the corresponding content and save the contents body" do
      c = FactoryGirl.create(:content)
      cat_cor = FactoryGirl.create(:category_correction, content: c)
      c = Content.find c.id
      c.category.should == cat_cor.new_category
      c.category_reviewed.should == true
      cat_cor.content_body.should == c.content
      cat_cor.title.should == c.title
    end

    it "should remove all previous category corrections attached to content" do
      c = FactoryGirl.create(:content)
      cat_cor_1 = FactoryGirl.create(:category_correction, content: c)
      cat_cor_2 = FactoryGirl.create(:category_correction, content: c)
      CategoryCorrection.where(content_id: c.id).count.should == 1
      CategoryCorrection.where(content_id: c.id)[0].should == cat_cor_2
    end

  end
end
