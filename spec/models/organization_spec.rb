# == Schema Information
#
# Table name: organizations
#
#  id                    :integer          not null, primary key
#  name                  :string(255)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  logo                  :string(255)
#  organization_id       :integer
#  website               :string(255)
#  publishing_frequency  :string(255)
#  notes                 :text
#  parent_id             :integer
#  category_override     :string(255)
#  tagline               :text
#  links                 :text
#  social_media          :text
#  general               :text
#  header                :text
#  pub_type              :string(255)
#  display_attributes    :boolean          default(FALSE)
#  reverse_publish_email :string(255)
#  can_reverse_publish   :boolean          default(FALSE)
#

require 'spec_helper'

describe Organization do
  before do
    @organization = FactoryGirl.create(:organization)
  end

  describe "latest_presentation" do
    it "should return nil if there are no presentation contents" do
      @organization.latest_presentation.should == nil
    end

    it "should return the most recent presentation content" do
      c1 = FactoryGirl.create(:content, pubdate: 1.day.ago, organization: @organization, category: "presentation")
      c2 = FactoryGirl.create(:content, pubdate: 2.days.ago, organization: @organization, category: "presentation")
      @organization.latest_presentation.should == c1
    end
  end

  describe 'get_all_children' do
    before do
      @s1 = FactoryGirl.create :organization, parent: @organization
      @s2 = FactoryGirl.create :organization, parent: @organization
      @c1 = FactoryGirl.create :organization, parent: @s1
      @c2 = FactoryGirl.create :organization, parent: @s2
    end

    it 'should respond with the descended tree' do
      @c1.get_all_children.should eq []
      @s1.get_all_children.should eq [@c1]
      @organization.get_all_children.should eq [@s1,@s2,@c1,@c2]
    end
  end
end
