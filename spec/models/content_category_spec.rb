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

describe ContentCategory, :type => :model do
  before do
    @content_category = FactoryGirl.create :content_category, name: 'lowercase name'
  end

  describe "#label" do
    it "returns titlecased name" do
      expect(@content_category.label).to eq "Lowercase Name"
    end
  end
end
