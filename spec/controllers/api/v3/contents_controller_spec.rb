require 'spec_helper'

describe Api::V3::ContentsController do
  before do
    @repo = FactoryGirl.create :repository
  end

  describe 'GET related_promotion' do
    before do
      @content = FactoryGirl.create :content
      @related_content = FactoryGirl.create(:content)
      Promotion.any_instance.stub(:update_active_promotions).and_return(true)
      @promo = FactoryGirl.create :promotion, content: @related_content
      @pb = FactoryGirl.create :promotion_banner, promotion: @promo
      Content.any_instance.stub(:get_related_promotion).and_return(@related_content.id)
    end

    subject { get :related_promotion, format: :json, 
              id: @content.id, repository_id: @repo.id }

    it 'has 200 status code' do
      subject
      response.code.should eq('200')
    end

    it 'should increment the impression count of the banner' do
      count = @pb.impression_count
      subject
      @pb.reload.impression_count.should eq(count+1)
    end

    describe 'logging content displayed with' do

      it 'should create a ContentPromotionBannerImpression record if none exists' do
        subject
        ContentPromotionBannerImpression.count.should eq(1)
        ContentPromotionBannerImpression.first.content_id.should eq(@content.id)
        ContentPromotionBannerImpression.first.promotion_banner_id.should eq(@pb.id)
      end

      it 'should increment the ContentPromotionBannerImpression display count if a record exists' do
        cpbi = FactoryGirl.create :content_promotion_banner_impression, content_id: @content.id, promotion_banner_id: @pb.id
        subject
        cpbi.reload.display_count.should eq(2)
      end
      
    end

  end

  describe 'GET similar_content' do
    before do
      @content_id = FactoryGirl.create(:content).id
      @sim_content = FactoryGirl.create :content
      Content.any_instance.stub(:similar_content).with(@repo, 20).and_return([@sim_content])
    end

    subject { get :similar_content, format: :json,
        id: @content_id, repository: @repo.dsp_endpoint }

    it 'has 200 status code' do
      subject
      response.code.should eq('200')
    end

    it 'responds with relation of similar content' do
      subject
      assigns(:contents).should eq([@sim_content])
    end
  end

end
