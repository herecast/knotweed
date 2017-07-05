require 'spec_helper'

describe Api::V3::PromotionBannersController, :type => :controller do

  describe 'GET index' do
    before do
      @user = FactoryGirl.create :user
      api_authenticate user: @user
    end

    subject { get :index, format: :json }

    describe 'organization\'s promotion banners' do
      before do
        @org = FactoryGirl.create :organization
        @org_pbs = FactoryGirl.create_list :promotion_banner, 2
        @org_pbs.each do |pb|
          pb.promotion.content.update_attribute :organization, @org
          # ensure promotions aren't created by user to test this fully
          pb.promotion.update_column :created_by, nil
        end
      end

      subject { get :index, format: :json, organization_id: @org.id }

      context 'as manager of organization' do
        before { @user.add_role :manager, @org }

        it 'should respond with the organization pbs' do
          subject
          expect(assigns(:promotion_banners)).to match_array(@org_pbs)
        end
      end

      context 'without organization privileges' do
        it 'should respond with no content' do
          subject
          expect(response.status).to eq 204
        end
      end
    end

    describe 'user\'s promotion banners' do
      before do
        @user_pbs = FactoryGirl.create_list :promotion_banner, 2,
          created_by: @user
      end

      it 'should respond with 200' do
        subject
        expect(response.status).to eq 200
      end

      it 'should return all promotion banners' do
        subject
        expect(assigns(:promotion_banners).sort).to eq PromotionBanner.all.sort
        end

      describe 'sorting'  do
        it 'accepts pubdate for sort' do
          PromotionBanner.first.promotion.content.update_attribute :pubdate, 1.day.ago
          get :index, format: :json, sort: 'pubdate DESC'
          expect(assigns(:promotion_banners).first).to eq PromotionBanner.all.sort_by{|p| p.promotion.content.pubdate}.last

          get :index, format: :json, sort: 'pubdate ASC'
          expect(assigns(:promotion_banners).first).to eq PromotionBanner.all.sort_by{|p| p.promotion.content.pubdate}.first
        end
        it 'accepts title for sort' do
          get :index, format: :json, sort: 'title DESC'
          expect(assigns(:promotion_banners).first).to eq PromotionBanner.all.sort_by{|p| p.promotion.content.title}.last

          get :index, format: :json, sort: 'title ASC'
          expect(assigns(:promotion_banners).first).to eq PromotionBanner.all.sort_by{|p| p.promotion.content.title}.first
        end
      end
    end
  end

  describe 'GET show' do
    before do
      @repo = FactoryGirl.create :repository
      @consumer_app = FactoryGirl.create :consumer_app, repository: @repo
      @org = FactoryGirl.create :organization
      @consumer_app.organizations = [@org]
      @content = FactoryGirl.create :content
      @related_content = FactoryGirl.create(:content)
      allow_any_instance_of(Promotion).to receive(:update_active_promotions).and_return(true)
      @promo = FactoryGirl.create :promotion, content: @related_content
      @pb = FactoryGirl.create :promotion_banner, promotion: @promo
      # avoid making calls to repo
      allow(DspService).to receive(:get_related_promo_ids).and_return([])
    end

    subject { get :show, format: :json,
              content_id: @content.id, consumer_app_uri: @consumer_app.uri }

    it 'has 200 status code' do
      subject
      expect(response.code).to eq('200')
    end

    context "when most_recent_reset_time is nil" do
      before do
        Rails.cache.clear
      end

      it "runs background job to clear daily impressions and to record 'load' event" do
        ENV['STACK_NAME'] = "knotweed-production"
        expect(BackgroundJob).to receive(:perform_later).with(
          "PrimeDailyPromotionBannerReports", "call", Date.current.to_s, true
        )
        expect(BackgroundJob).to receive(:perform_later).with(
          "RecordPromotionBannerMetric", "call", hash_including({
            promotion_banner_id: @pb.id
          })
        )
        subject
      end

      context "when environment is non-prod" do
        it "primes reports with is_prod=false" do
          ENV['STACK_NAME'] = "hoth-qa"
          expect(BackgroundJob).to receive(:perform_later).with(
            "PrimeDailyPromotionBannerReports", "call", Date.current.to_s, false
          )
          expect(BackgroundJob).to receive(:perform_later).with(
          "RecordPromotionBannerMetric", "call", hash_including({
            promotion_banner_id: @pb.id
          })
        )
          subject
        end
      end
    end

    context "when most_recent_reset_time is from the previous day" do
      before do
        Rails.cache.write('most_recent_reset_time', Date.yesterday)
      end

      it "runs background job to clear daily impressions and to record 'load' event" do
        ENV['STACK_NAME'] = "knotweed-production"
        expect(BackgroundJob).to receive(:perform_later).with(
          "PrimeDailyPromotionBannerReports", "call", Date.current.to_s, true
        )
        expect(BackgroundJob).to receive(:perform_later).with(
          "RecordPromotionBannerMetric", "call", hash_including({
            promotion_banner_id: @pb.id
          })
        )
        subject
      end
    end

    context "when most_recent_reset_time is from current day" do
      before do
        Rails.cache.write('most_recent_reset_time', Date.current)
      end

      subject { get :show, format: :json,
              promotion_id: @promo.id, consumer_app_uri: @consumer_app.uri }

      it "records 'load' event" do
        expect(BackgroundJob).to receive(:perform_later).with(
          "RecordPromotionBannerMetric", "call", hash_including({
            event_type: 'load',
            user_id: nil,
            promotion_banner_id: @pb.id
          })
        )
        subject
      end
    end

    context 'as a user with skip_analytics = true' do
      before do
        @user = FactoryGirl.create :user, skip_analytics: true
        api_authenticate user: @user
      end

      it 'should not call record_promotion_banner_metric' do
        expect(BackgroundJob).not_to receive(:perform_later).with(
          'RecordPromotionBannerMetric', "call", any_args
        )
        subject
      end
    end

    context 'with banner_ad_override' do
      before do
        @promo2 = FactoryGirl.create :promotion, content: FactoryGirl.create(:content)
        @pb2 = FactoryGirl.create :promotion_banner, promotion: @promo2
        @content.update_attribute :banner_ad_override, @promo2.id
      end

      it 'should respond with the banner specified by the banner_ad_override' do
        subject
        expect(assigns(:promotion_banners).first).to eq @pb2
      end
    end

  end

  describe 'post track_impression' do
    let(:location) { FactoryGirl.create :location }
    before do
      @banner = FactoryGirl.create :promotion_banner
      @content = FactoryGirl.create :content
    end

    subject {
      post :track_impression,
        id: @banner.id,
        client_id: "ClientID!",
        location_id: location.slug,
        format: :json
    }

    it 'should respond with 200' do
      subject
      expect(response.status).to eq 200
    end

    it "calls record_promotion_banner_metric with 'impression'" do
      expect(BackgroundJob).to receive(:perform_later).with(
        'RecordPromotionBannerMetric', "call", hash_including({
          event_type: "impression",
          promotion_banner_id: @banner.id,
          client_id: 'ClientID!',
          location_id: location.id
        })
      )
      subject
    end

    context 'as a user with skip_analytics = true' do
      before do
        @user = FactoryGirl.create :user, skip_analytics: true
        api_authenticate user: @user
      end

      it 'should not call record_promotion_banner_metric' do
        expect(BackgroundJob).not_to receive(:perform_later).with(
          'RecordPromotionBannerMetric', "call", any_args
        )
        subject
      end
    end
  end

  describe 'post track_click' do
    let(:location) { FactoryGirl.create :location }
    before do
      @banner = FactoryGirl.create :promotion_banner
      @content = FactoryGirl.create :content
      @content.promotion_banners = [@banner]
    end

    subject {
      post :track_click,
        promotion_banner_id: @banner.id,
        content_id: @content.id,
        client_id: 'ClientId@',
        location_id: location.slug,
        format: :json
    }

    it 'should respond with 200' do
      subject
      expect(response.status).to eq 200
    end

    it "calls record_promotion_banner_metric with 'click" do
      expect(BackgroundJob).to receive(:perform_later).with(
        "RecordPromotionBannerMetric", "call", hash_including({
          event_type: 'click',
          user_id: nil,
          client_id: 'ClientId@',
          location_id: location.id,
          promotion_banner_id: @banner.id,
          current_date: Date.current.to_s,
          content_id: @content.id
        })
      )
      expect(BackgroundJob).to receive(:perform_later).with(
        'RecordContentMetric', 'call', @content, 'click', Date.current.to_s,
          { user_id: nil, client_id: 'ClientId@' }
      )
      subject
    end

    context 'as a user with skip_analytics = true' do
      before do
        @user = FactoryGirl.create :user, skip_analytics: true
        api_authenticate user: @user
      end

      it 'should not call record_promotion_banner_metric' do
        expect(BackgroundJob).not_to receive(:perform_later).with(
          'RecordPromotionBannerMetric', "call", any_args
        )
        subject
      end
    end

    context 'with content id missing' do
      subject { post :track_click, promotion_banner_id: @banner.id, format: :json }

      it 'should respond with 200' do
        subject
        expect(response.status).to eq 200
      end
    end


    context 'with invalid promotion_banner_id' do
      subject! { post :track_click, promotion_banner_id: @banner.id + 201, content_id: @content.id, format: :json }
      it 'should return 422' do
        expect(response.status).to eq 422
      end
    end
  end

  describe "POST #create_ad_metric" do
    context "when params contain ad_metric" do
      subject { post :create_ad_metric, { ad_metric: {
        campaign: 'under-laser-cta',
        event_type: 'click',
        page_url: 'dailyuv.com/death-star-adverts',
        content: 'Want to advertise with the Republic?'
      } } }

      it "creates ad_metric" do
        expect{ subject }.to change{
          AdMetric.count
        }.by 1
      end

      context "when user is admin" do
        before do
          user = FactoryGirl.create :user, skip_analytics: true
          api_authenticate user: user
        end

        it "does not record metric" do
          expect{ subject }.not_to change{
            AdMetric.count
          }
        end
      end
    end
  end

  describe "GET #show_promotion_coupon" do
    context "when promotion_banner does not exist" do
      subject { get :show_promotion_coupon, id: '40 billion' }

      it "returns not_found status" do
        subject
        expect(response).to have_http_status :not_found
      end
    end

    context "when promotion_banner exists" do
      before do
        @promotion_banner = FactoryGirl.create :promotion_banner
      end

      subject { get :show_promotion_coupon, id: @promotion_banner.id }

      context "when not a coupon" do
        it "returns not_found status" do
          subject
          expect(response).to have_http_status :not_found
        end
      end

      context "when a coupon" do
        before do
          @promotion_banner.update_attribute :promotion_type, PromotionBanner::COUPON
        end

        it "returns ok status" do
          subject
          expect(response).to have_http_status :ok
        end
      end
    end
  end

  describe "POST #create_promotion_coupon_email" do
    context "when promotion_banner does not exist" do
      subject { post :create_promotion_coupon_email, id: '40 billion' }

      it "returns bad_request status" do
        subject
        expect(response).to have_http_status :bad_request
      end
    end

    context "when promotion_banner exists" do
      before do
        @promotion_banner = FactoryGirl.create :promotion_banner
        @email = 'darth@deathstar.com'
      end

      subject { post :create_promotion_coupon_email, id: @promotion_banner.id, email: @email }

      it "sends email to user" do
        mail = double()
        expect(mail).to receive(:deliver_later)
        expect(AdMailer).to receive(:coupon_request)
          .with(@email, @promotion_banner)
          .and_return(mail)
        subject
      end

      it "returns ok status" do
        subject
        expect(response).to have_http_status :ok
      end
    end
  end

  describe 'GET /promotion_banners/:id/metrics' do
    before do
      @banner = FactoryGirl.create :promotion_banner
      @user = FactoryGirl.create :user
      @content = FactoryGirl.create :content
      @content.promotion_banners = [@banner]
      api_authenticate user: @user
    end

    subject { get :metrics, id: @banner.id }

    context 'without owning the content' do
      before do
        @banner.promotion.update_attribute :created_by, nil
      end

      it 'should respond with 401' do
        subject
        expect(response.code).to eq('401')
      end
    end

    context 'as content owner' do
      before do
        @banner.promotion.update_attribute :created_by, @user
      end

      it 'should respond with the content' do
        subject
        expect(assigns(:promotion_banner)).to eq(@banner)
      end
    end

    context 'as organization manager' do
      before do
        organization = FactoryGirl.create :organization
        @banner.promotion.update_attribute :organization_id, organization.id
        @user.add_role :manager, organization
      end

      it "should respond with content" do
        subject
        expect(assigns(:promotion_banner)).to eq @banner
      end
    end
  end
end
