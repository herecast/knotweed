require 'spec_helper'

RSpec.describe CampaignsController, type: :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
    @campaigns = FactoryGirl.create_list :promotion_banner, 4, campaign_end: Date.current - 5
    @content_category = FactoryGirl.create :content_category, name: 'campaign'
    @campaigns.each do |c|
      promotion = FactoryGirl.create :promotion, promotable_id: c.id, promotable_type: 'PromotionBanner'
      promotion.content = FactoryGirl.create :content, content_category_id: @content_category.id
      promotion.save
    end
  end

  describe "GET #index" do
    context 'when reset' do
      subject { get :index, { q: nil, reset: true } }

      it "returns no campaigns" do
        subject
        expect(assigns(:campaigns)).to eq []
      end
    end

    context 'when default search' do
      subject { get :index }

      it "returns all campaigns" do
        subject
        expect(assigns(:campaigns)).to match_array @campaigns
      end
    end

    context 'when id is given' do
      subject { get :index, { q: { promotion_content_id_eq: @campaigns.first.promotion.content.id } } }

      it "finds matching campaign" do
        subject
        expect(assigns(:campaigns)).to match_array [@campaigns.first]
      end
    end

    context 'when organization is given' do
      before do
        @organization = FactoryGirl.create :organization
        @org_campaign = @campaigns.first
        @org_campaign.promotion.update_attribute(:organization_id, @organization.id)
      end

      subject { get :index, { q: { promotion_organization_id_eq: @organization.id } } }

      it "returns campaigns owned by organization" do
        subject
        expect(assigns(:campaigns)).to match_array [@org_campaign]
      end
    end

    context "when paid checkbox is clicked" do
      before do
        @paid_campaign = @campaigns.first
        @paid_campaign.promotion.update_attribute(:paid, true)
      end

      subject { get :index, { q: { promotion_paid_eq: true } } }

      it "returns paid campaigns" do
        subject
        expect(assigns(:campaigns)).to match_array [@paid_campaign]
      end
    end

    context "when active checkbox is clicked" do
      before do
        @active_campaign = @campaigns.first
        @active_campaign.update_attribute(:campaign_end, Date.current + 1)
      end

      subject { get :index, { q: { campaign_end_gteq: Date.current } } }

      it "returns active promotions" do
        subject
        expect(assigns(:campaigns)).to match_array [@active_campaign] 
      end
    end

    context "when boosted checkbox is clicked" do
      before do
        @boosted_campaign = @campaigns.first
        @boosted_campaign.update_attribute(:boost, true)
      end

      subject { get :index, { q: { boost_eq: true } } }

      it "returns boosted campaigns" do
        subject
        expect(assigns(:campaigns)).to match_array [@boosted_campaign]
      end
    end
  end
end
