# == Schema Information
#
# Table name: content_categories
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  parent_id  :integer
#


require 'spec_helper'

describe ContentCategory do

  describe "cats_and_children_from_name_list" do
    before do
      @base_cat_1, @base_cat_2 = FactoryGirl.create_list(:content_category, 2)
      @child_cat = FactoryGirl.create :content_category, parent: @base_cat_2
    end

    it "should return the appropriate categories based on name queries" do
      ContentCategory.find_with_children(name: @child_cat.name).count.should == 1
      ContentCategory.find_with_children(name: @base_cat_1.name).count.should == 1
      ContentCategory.find_with_children(name: @base_cat_2.name).count.should == 2
      ContentCategory.find_with_children(name: [@base_cat_2.name, @base_cat_1.name]).count.should == 3
    end

  end

end
