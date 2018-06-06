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

describe CategoryCorrection, :type => :model do
  describe "after_create" do
    it "should update the category of the corresponding content and save the contents body" do
      c = FactoryGirl.create(:content)
      cat_cor = FactoryGirl.create(:category_correction, content: c)
      c = Content.find c.id
      expect(c.category).to eq(cat_cor.new_category)
      expect(c.category_reviewed).to eq(true)
      expect(cat_cor.content_body).to eq(c.content)
      expect(cat_cor.title).to eq(c.title)
    end

    it "should remove all previous category corrections attached to content" do
      c = FactoryGirl.create(:content)
      cat_cor_1 = FactoryGirl.create(:category_correction, content: c)
      cat_cor_2 = FactoryGirl.create(:category_correction, content: c)
      expect(CategoryCorrection.where(content_id: c.id).count).to eq(1)
      expect(CategoryCorrection.where(content_id: c.id)[0]).to eq(cat_cor_2)
    end

  end

end
