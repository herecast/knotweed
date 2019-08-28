require 'spec_helper'

RSpec.describe SendExternalAdvertiserReportsJob do
  before do
    campaign_category = FactoryGirl.create :content_category, name: 'campaign'
    @organization = FactoryGirl.create :organization
    @active_campaign_1 = FactoryGirl.create :content,
      content_category_id: campaign_category.id,
      ad_campaign_start: 9.days.ago,
      ad_campaign_end: 2.days.ago,
      organization_id: @organization.id,
      ad_promotion_type: 'ROS',
      promotions: [FactoryGirl.create(:promotion)]
     @active_campaign_2 = FactoryGirl.create :content,
      content_category_id: campaign_category.id,
      ad_campaign_start: 9.days.ago,
      ad_campaign_end: 2.days.from_now,
      organization_id: @organization.id,
      ad_promotion_type: 'ROS',
      promotions: [FactoryGirl.create(:promotion)]
     @active_campaign_3 = FactoryGirl.create :content,
      content_category_id: campaign_category.id,
      ad_campaign_start: 4.days.ago,
      ad_campaign_end: 2.days.from_now,
      organization_id: @organization.id,
      ad_promotion_type: 'ROS',
      promotions: [FactoryGirl.create(:promotion)]
    @innactive_campaign_past = FactoryGirl.create :content,
      content_category_id: campaign_category.id,
      ad_campaign_start: 20.days.ago,
      ad_campaign_end: 10.days.ago,
      organization_id: @organization.id,
      ad_promotion_type: 'ROS',
      promotions: [FactoryGirl.create(:promotion)]
    @innactive_campaign_future = FactoryGirl.create :content,
      content_category_id: campaign_category.id,
      ad_campaign_start: 2.days.from_now,
      ad_campaign_end: 10.days.from_now,
      organization_id: @organization.id,
      ad_promotion_type: 'ROS',
      promotions: [FactoryGirl.create(:promotion)]
    @non_campaign_content = FactoryGirl.create :content, :news,
      organization_id: @organization.id
    mail = double(deliver_later: true)
    allow(PromotionsMailer).to receive(
      :external_advertiser_report
    ).and_return(mail)
  end

  subject { SendExternalAdvertiserReportsJob.perform_now }

  it "makes correct calls to promotions mailer" do
    expect(PromotionsMailer).to receive(:external_advertiser_report).with(
      organization: @organization,
      campaigns: array_including(@active_campaign_1, @active_campaign_2, @active_campaign_3)
    )
    subject
  end
end