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
        @user_pbs = FactoryGirl.create_list :promotion_banner, 2
        # need to set this manually to ensure that it's set in time
        # for the example to run
        @user_pbs.each do |pb|
          pb.promotion.update_column :created_by, @user.id
        end
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

  describe 'post track_click' do
    before do
      @banner = FactoryGirl.create :promotion_banner
      @content = FactoryGirl.create :content
      @content.promotion_banners = [@banner]
    end

    subject { post :track_click, promotion_banner_id: @banner.id,
               content_id: @content.id, format: :json }

    it 'should respond with 200' do
      subject
      expect(response.status).to eq 200
    end

    it 'should increment content.banner_click_count' do
      expect{subject}.to change{@content.reload.banner_click_count}.by 1
    end

    it 'should increment banner.click_count' do
      expect{subject}.to change{@banner.reload.click_count}.by 1
    end

    context 'as a user with skip_analytics = true' do
      before do
        @user = FactoryGirl.create :user, skip_analytics: true
        api_authenticate user: @user
      end

      it 'should not increment content.banner_click_count' do
        expect{subject}.not_to change{@content.reload.banner_click_count}
      end

      it 'should not increment banner.click_count' do
        expect{subject}.not_to change{@banner.reload.click_count}
      end
    end

    context 'with invalid content id' do
      subject! { post :track_click, promotion_banner_id: @banner.id, content_id: @content.id + 200, format: :json }
      it 'should return 422' do
        expect(response.status).to eq 422
      end
    end

    context 'with invalid promotion_banner_id' do
      subject! { post :track_click, promotion_banner_id: @banner.id + 201, content_id: @content.id, format: :json }
      it 'should return 422' do
        expect(response.status).to eq 422
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
  end
end
