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

  describe "::parent_pubs" do
    before do
      @parent_org_1 = FactoryGirl.create :organization
      @parent_org_2 = FactoryGirl.create :organization, parent: @parent_org_1
      @child_org    = FactoryGirl.create :organization, parent: @parent_org_2
    end

    it "returns list of parent organizations" do
      list = Organization.parent_pubs
      expect(list).to match_array([@parent_org_1, @parent_org_2])
    end
  end

  describe '#business_location_options' do
    before do
      @organization = FactoryGirl.create :organization
      @organization.business_locations << FactoryGirl.create(:business_location)
      @organization.business_locations << FactoryGirl.create(:business_location)
    end

    it "returns all of organizations business locations" do
      locations = @organization.business_location_options
      expect(locations.length).to eq 2
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
