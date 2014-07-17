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
      c.categories.should == cat_cor.new_category
      cat_cor.content_body.should == c.content
      cat_cor.title.should == c.title
    end
  end
end
