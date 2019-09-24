require 'spec_helper'

describe Api::V3::ContentMetricsSerializer do
  let(:promotion_banner) { FactoryGirl.create :promotion_banner }
  let!(:click1_day1) { FactoryGirl.create :promotion_banner_metric, promotion_banner: promotion_banner,
                       created_at: 3.days.ago, event_type: 'click' }
  let!(:click2_day1) { FactoryGirl.create :promotion_banner_metric, promotion_banner: promotion_banner,
                       created_at: 3.days.ago, event_type: 'click' }
  let!(:click1_day2) { FactoryGirl.create :promotion_banner_metric, promotion_banner: promotion_banner,
                         created_at: 1.day.ago, event_type: 'click' }

  subject { JSON.parse(Api::V3::PromotionBannerMetricsSerializer.new(promotion_banner,
                                                                     root: false, context: {}).to_json) }

  describe 'daily click counts' do
    it 'should render an array of daily click counts' do
      expect(subject['daily_click_counts'].length).to eq 2
    end
  end
end
