require 'rails_helper'

RSpec.describe 'Promotion Coupons Endpoint', type: :request do
  describe 'GET /api/v3/promotion_coupons/:id' do
    before do
      @message = 'When I was a boy on Tatooine...'
      @promotion_coupon = FactoryGirl.create :promotion_banner,
                                             coupon_image: File.open(File.join(Rails.root, '/spec/fixtures/photo.jpg')),
                                             coupon_email_body: @message,
                                             promotion_type: 'Coupon'
    end

    subject { get "/api/v3/promotion_coupons/#{@promotion_coupon.id}" }

    it "returns promotion_coupon information" do
      subject
      expect(response_json).to match(
        promotion_coupon: {
          id: @promotion_coupon.id,
          promotion_id: @promotion_coupon.promotion.id,
          image_url: @promotion_coupon.coupon_image.url,
          promotion_type: 'Coupon',
          title: @promotion_coupon.promotion.content.title,
          message: @message
        }
      )
    end
  end
end
