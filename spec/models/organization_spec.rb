# == Schema Information
#
# Table name: organizations
#
#  id                  :integer          not null, primary key
#  name                :string(255)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  logo                :string(255)
#  organization_id     :integer
#  website             :string(255)
#  notes               :text
#  parent_id           :integer
#  org_type            :string(255)
#  can_reverse_publish :boolean          default(FALSE)
#  can_publish_news    :boolean          default(FALSE)
#  subscribe_url       :string(255)
#  description         :text
#  pay_rate_in_cents   :integer          default(0)
#  banner_ad_override  :string(255)
#  profile_title       :string(255)
#  pay_directly        :boolean          default(FALSE)
#  can_publish_events  :boolean          default(FALSE)
#  can_publish_market  :boolean          default(FALSE)
#  can_publish_talk    :boolean          default(FALSE)
#  can_publish_ads     :boolean          default(FALSE)
#  profile_image       :string(255)
#  background_image    :string(255)
#  profile_ad_override :string(255)
#  custom_links        :jsonb
#

require 'spec_helper'

describe Organization, :type => :model do
  it {is_expected.to have_db_column(:profile_title)}

  before do
    @organization = FactoryGirl.create(:organization)
  end

  describe "validations" do
    context "when Twitter handle does not begin with @" do
      it "is not valid" do
        organization = FactoryGirl.build :organization, twitter_handle: 'jango_fett'
        expect(organization).not_to be_valid
      end
    end

    context "when Twitter handle begins with @" do
      it "is valid" do
        organization = FactoryGirl.build :organization, twitter_handle: '@jango_fett'
        expect(organization).to be_valid
      end
    end
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
      expect(@c1.get_all_children).to eq []
      expect(@s1.get_all_children).to eq [@c1]
      expect(@organization.get_all_children).to eq [@s1,@s2,@c1,@c2]
    end
  end

  describe '.news_publishers' do
    it 'includes Blog, Publisher, and Publication type organizations' do
      expect { FactoryGirl.create(:organization, org_type: 'Blog'       ) }.to change{Organization.news_publishers.count}.by(1)
      expect { FactoryGirl.create(:organization, org_type: 'Publisher'  ) }.to change{Organization.news_publishers.count}.by(1)
      expect { FactoryGirl.create(:organization, org_type: 'Publication') }.to change{Organization.news_publishers.count}.by(1)
    end

    it 'ignores other types of organizations' do
      expect { FactoryGirl.create(:organization, org_type: 'Community') }.not_to change{Organization.news_publishers.count}
    end
  end

  describe '.descendants_of' do
    subject            { FactoryGirl.create(:organization) }
    let!(:child1)      { FactoryGirl.create(:organization, parent: subject) }
    let!(:child2)      { FactoryGirl.create(:organization, parent: subject) }
    let!(:grand_child) { FactoryGirl.create(:organization, parent: child1) }

    it 'includes children' do
      expect {
        FactoryGirl.create(:organization, parent: subject)
      }.to change{Organization.descendants_of(subject.id).count}.by 1
    end

    it 'includes grand-children' do
      expect {
        FactoryGirl.create(:organization, parent: child1)
      }.to change{Organization.descendants_of(subject.id).count}.by 1
    end

    it 'includes great-grand-children' do
      expect {
        FactoryGirl.create(:organization, parent: grand_child)
      }.to change{Organization.descendants_of(subject.id).count}.by 1
    end

    it 'ignores non-descendants' do
      expect {
        non_descendant = FactoryGirl.create(:organization)
        expect(non_descendant.parent).to_not eq subject
      }.not_to change{Organization.descendants_of(subject.id).count}
    end
  end
end
