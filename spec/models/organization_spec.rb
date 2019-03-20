# frozen_string_literal: true
# == Schema Information
#
# Table name: organizations
#
#  id                       :bigint(8)        not null, primary key
#  name                     :string(255)
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  logo                     :string(255)
#  organization_id          :bigint(8)
#  website                  :string(255)
#  notes                    :text
#  parent_id                :bigint(8)
#  org_type                 :string(255)
#  can_reverse_publish      :boolean          default(FALSE)
#  can_publish_news         :boolean          default(FALSE)
#  description              :text
#  banner_ad_override       :string(255)
#  pay_directly             :boolean          default(FALSE)
#  profile_image            :string(255)
#  background_image         :string(255)
#  twitter_handle           :string
#  custom_links             :jsonb
#  biz_feed_active          :boolean          default(FALSE)
#  ad_sales_agent           :string
#  ad_contact_nickname      :string
#  ad_contact_fullname      :string
#  profile_sales_agent      :string
#  certified_storyteller    :boolean          default(FALSE)
#  services                 :string
#  contact_card_active      :boolean          default(TRUE)
#  description_card_active  :boolean          default(TRUE)
#  hours_card_active        :boolean          default(TRUE)
#  pay_for_content          :boolean          default(FALSE)
#  special_link_url         :string
#  special_link_text        :string
#  certified_social         :boolean          default(FALSE)
#  desktop_image            :string
#  archived                 :boolean          default(FALSE)
#  feature_notification_org :boolean          default(FALSE)
#  standard_ugc_org         :boolean          default(FALSE)
#  calendar_view_first      :boolean          default(FALSE)
#  calendar_card_active     :boolean          default(FALSE)
#  embedded_ad              :boolean          default(TRUE)
#  digest_id                :integer
#  reminder_campaign_id     :string
#  mc_segment_id            :string
#
# Indexes
#
#  idx_16739_index_publications_on_name  (name) UNIQUE
#

require 'spec_helper'

describe Organization, type: :model do
  it { is_expected.to have_many :organization_locations }
  it { is_expected.to have_many :locations }

  describe '#base_locations' do
    let(:organization) { FactoryGirl.create :organization }
    let(:non_base) { FactoryGirl.create_list :location, 3 }
    let(:base) { FactoryGirl.create_list :location, 3 }

    before do
      non_base.each do |location|
        OrganizationLocation.create(
          organization: organization,
          location: location
        )
      end

      base.each do |location|
        OrganizationLocation.create(
          organization: organization,
          location: location,
          location_type: 'base'
        )
      end
    end

    it 'returns locations specified as "base"' do
      expect(organization.base_locations).to include(*base)
      expect(organization.base_locations).to_not include(*non_base)
    end
  end

  before do
    @organization = FactoryGirl.create(:organization)
  end

  describe 'validations' do
    context 'when Twitter handle does not begin with @' do
      it 'is not valid' do
        organization = FactoryGirl.build :organization, twitter_handle: 'jango_fett'
        expect(organization).not_to be_valid
      end
    end

    context 'when Twitter handle begins with @' do
      it 'is valid' do
        organization = FactoryGirl.build :organization, twitter_handle: '@jango_fett'
        expect(organization).to be_valid
      end
    end
  end

  describe '::parent_pubs' do
    before do
      @parent_org_1 = FactoryGirl.create :organization
      @parent_org_2 = FactoryGirl.create :organization, parent: @parent_org_1
      @child_org    = FactoryGirl.create :organization, parent: @parent_org_2
    end

    it 'returns list of parent organizations' do
      list = Organization.parent_pubs
      expect(list).to match_array([@parent_org_1, @parent_org_2])
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
      expect(@organization.get_all_children).to eq [@s1, @s2, @c1, @c2]
    end
  end

  describe '.news_publishers' do
    it 'includes Blog, Publisher, and Publication type organizations' do
      expect { FactoryGirl.create(:organization, org_type: 'Blog') }.to change { Organization.news_publishers.count }.by(1)
      expect { FactoryGirl.create(:organization, org_type: 'Publisher') }.to change { Organization.news_publishers.count }.by(1)
      expect { FactoryGirl.create(:organization, org_type: 'Publication') }.to change { Organization.news_publishers.count }.by(1)
    end

    it 'ignores other types of organizations' do
      expect { FactoryGirl.create(:organization, org_type: 'Community') }.not_to change { Organization.news_publishers.count }
    end
  end

  describe '.descendants_of' do
    subject            { FactoryGirl.create(:organization) }
    let!(:child1)      { FactoryGirl.create(:organization, parent: subject) }
    let!(:child2)      { FactoryGirl.create(:organization, parent: subject) }
    let!(:grand_child) { FactoryGirl.create(:organization, parent: child1) }

    it 'includes children' do
      expect do
        FactoryGirl.create(:organization, parent: subject)
      end.to change { Organization.descendants_of(subject.id).count }.by 1
    end

    it 'includes grand-children' do
      expect do
        FactoryGirl.create(:organization, parent: child1)
      end.to change { Organization.descendants_of(subject.id).count }.by 1
    end

    it 'includes great-grand-children' do
      expect do
        FactoryGirl.create(:organization, parent: grand_child)
      end.to change { Organization.descendants_of(subject.id).count }.by 1
    end

    it 'ignores non-descendants' do
      expect do
        non_descendant = FactoryGirl.create(:organization)
        expect(non_descendant.parent).to_not eq subject
      end.not_to change { Organization.descendants_of(subject.id).count }
    end
  end

  describe 'Updating locations, profile image, or name, triggers a reindex of linked content' do
    subject { FactoryGirl.create :organization }

    describe 'adding locations' do
      let(:location) { FactoryGirl.create :location }

      it do
        expect do
          subject.organization_locations << OrganizationLocation.new(
            location: location
          )
          subject.save!
        end.to have_enqueued_job(ReindexAssociatedContentJob).with(subject)
      end
    end

    describe 'updating locations' do
      let(:location) { FactoryGirl.create :location }
      before do
        subject.organization_locations << OrganizationLocation.new(
          location: location
        )
      end

      it do
        expect do
          subject.update! organization_locations_attributes: [
            subject.organization_locations.first.attributes.merge(
              location_type: 'about'
            )
          ]
        end.to have_enqueued_job(ReindexAssociatedContentJob).with(subject)
      end
    end

    describe 'removing locations' do
      let(:location) { FactoryGirl.create :location }

      before do
        subject.organization_locations << OrganizationLocation.new(
          location: location
        )
      end

      it do
        expect do
          subject.organization_locations.last.destroy
        end.to have_enqueued_job(ReindexAssociatedContentJob).with(subject)
      end
    end

    describe 'changing organization name' do
      it do
        expect do
          subject.update! name: 'new org'
        end.to have_enqueued_job(ReindexAssociatedContentJob).with(subject)
      end
    end

    describe 'changing organization profile image' do
      it do
        expect do
          subject.update! profile_image: 'newimg.jpg'
        end.to have_enqueued_job(ReindexAssociatedContentJob).with(subject)
      end
    end

    describe 'changing a non-dependent attribute' do
      it 'does not trigger reindex' do
        expect do
          subject.update! website: 'http://dublin-brews.com'
        end.to_not have_enqueued_job(ReindexAssociatedContentJob)
      end
    end
  end

  describe '#has_business_profile?' do
    let(:organization) { FactoryGirl.create :organization }

    context 'when no related BusinessProfile' do
      it 'returns false' do
        expect(organization.has_business_profile?).to be false
      end
    end

    context 'when related BusinessProfile present' do
      before do
        organization.contents << FactoryGirl.create(:content, channel_type: 'BusinessProfile')
      end

      it 'returns true' do
        expect(organization.has_business_profile?).to be true
      end
    end
  end

  describe '#post_count' do
    let(:organization) { FactoryGirl.create :organization }
    subject { organization.post_count }

    context 'when the org has comments' do
      let!(:comment) { FactoryGirl.create :content, :comment, organization: organization }

      it 'should not include comments in the count' do
        expect(subject).to eq 0
      end
    end

    context 'when the org has ads' do
      let!(:ad) { FactoryGirl.create :content, :campaign, organization: organization }

      it 'should not include ads in the count' do
        expect(subject).to eq 0
      end
    end

    context 'when the org has market, news, events' do
      let!(:market) { FactoryGirl.create :content, :market_post, organization: organization }
      let!(:news) { FactoryGirl.create :content, :news, organization: organization }
      let!(:event) { FactoryGirl.create :content, :event, organization: organization }

      it 'should include market, news, and events' do
        expect(subject).to eq 3
      end
    end

    context 'when the org has a future news post' do
      let!(:future_news) { FactoryGirl.create :content, :news, organization: organization, pubdate: 1.week.from_now }

      it 'should not include the future post' do
        expect(subject).to eq 0
      end
    end

    context 'when the org has a removed news post' do
      let!(:removed_news) { FactoryGirl.create :content, :news, organization: organization, removed: true }

      it 'should not include the removed post' do
        expect(subject).to eq 0
      end
    end

    context 'when the org has a biz_feed_public=FALSE post' do
      let!(:not_public_news) { FactoryGirl.create :content, :news, organization: organization, biz_feed_public: false }

      it 'should not include the unpublic post' do
        expect(subject).to eq 0
      end
    end
  end
end
