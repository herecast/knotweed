require 'spec_helper'

RSpec.describe CampaignsController, type: :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
    @campaigns = FactoryGirl.create_list :content, 4, :campaign,
      ad_campaign_start: Date.current - 4,
      ad_campaign_end: Date.current - 3
    @campaigns.each do |c|
      promotion = FactoryGirl.create :promotion
      c.promotions << promotion
    end
  end

  let(:new_title) { 'Hoth Racquet Sale!' }
  let(:valid_params) {{ content: {
    organization_id: 5,
    title: new_title,
    ad_campaign_start: Date.yesterday,
    ad_campaign_end: Date.tomorrow,
    ad_promotion_type: 'ROS'
  } }}

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
        expect(response).to have_http_status :ok
      end
    end

    context 'when id is given' do
      subject { get :index, { q: { id_eq: @campaigns.first.id } } }

      it "finds matching campaign" do
        subject
        expect(assigns(:campaigns)).to match_array [@campaigns.first]
      end
    end

    context 'when organization is given' do
      before do
        @organization = FactoryGirl.create :organization
        @org_campaign = @campaigns.first
        @org_campaign.update_attribute(:organization_id, @organization.id)
      end

      subject { get :index, { q: { organization_id_eq: @organization.id } } }

      it "returns campaigns owned by organization" do
        subject
        expect(assigns(:campaigns)).to match_array [@org_campaign]
      end
    end

    context "when paid checkbox is clicked" do
      before do
        @paid_campaign = @campaigns.first
        @paid_campaign.promotions.first.update_attribute(:paid, true)
      end

      subject { get :index, { q: { promotions_paid_eq: true } } }

      it "returns paid campaigns" do
        subject
        expect(assigns(:campaigns)).to match_array [@paid_campaign]
      end
    end

    context "when active checkbox is clicked" do
      before do
        @active_campaign = @campaigns.first
        @active_campaign.update_attributes(ad_campaign_start: Date.yesterday, ad_campaign_end: Date.tomorrow)
      end

      subject { get :index, { promotion_banners_active: 'on' } }

      it "returns active promotions" do
        subject
        expect(assigns(:campaigns)).to match_array [@active_campaign]
      end
    end

    context "when boosted checkbox is clicked" do
      before do
        @boosted_campaign = @campaigns.first
        promotion_banner = FactoryGirl.create :promotion_banner, boost: true
        promotion_banner.promotion.content = @boosted_campaign
        promotion_banner.promotion.save
      end

      subject { get :index, { q: { promotions_promotable_of_PromotionBanner_type_boost_eq: true } } }

      it "returns boosted campaigns" do
        subject
        expect(assigns(:campaigns)).to match_array [@boosted_campaign]
      end
    end
  end

  describe "GET #edit" do
    subject { get :edit, id: @campaigns.first.id }

    it "returns ok status" do
      subject
      expect(response).to have_http_status :ok
    end
  end

  describe "GET #new" do
    subject { get :new }

    it "returns ok status" do
      subject
      expect(response).to have_http_status :ok
    end
  end

  describe "POST #create" do
    context "when content saves" do
      subject { post :create, valid_params }

      it "creates campaign" do
        expect{ subject }.to change{
          Content.count
        }.by 1
      end
    end

    context "when content does not save" do
      before do
        allow_any_instance_of(Content).to receive(:save).and_return false
      end

      subject { post :create, valid_params }

      it "does not create campaign" do
        expect{ subject }.not_to change{
          Content.count
        }
      end
    end
  end

  describe "GET #edit" do
    subject { get :edit, id: @campaigns.first.id }

    it "returns ok status" do
      subject
      expect(response).to have_http_status :ok
    end
  end

  describe "PUT #edit" do
    let(:id) { @campaigns.first.id }

    context "when content updates" do
      subject { put :update, valid_params.merge({ id: id }) }

      it "creates campaign" do
        expect{ subject }.to change{
          @campaigns.first.reload.title
        }.to eq new_title
      end
    end

    context "when content does not update" do
      before do
        allow_any_instance_of(Content).to receive(:update_attributes).and_return false
      end

      subject { put :update, valid_params.merge({ id: id }) }

      it "does not create campaign" do
        expect{ subject }.not_to change{
          @campaigns.first.reload.title
        }
      end
    end
  end
end
