# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RecordPromotionBannerMetric do
  before do
    @promotion_banner = FactoryGirl.create :promotion_banner
  end

  describe '::call' do
    context 'with event_type: load' do
      subject do
        RecordPromotionBannerMetric.call(
          event_type: 'load',
          user_id: nil,
          promotion_banner_id: @promotion_banner.id,
          current_date: Date.current.to_s
        )
      end

      it 'reports load event' do
        expect { subject }.to change {
          PromotionBannerMetric.where(event_type: 'load').count
        }.by 1
      end

      it 'increases load count of promotion_banner' do
        expect { subject }.to change {
          @promotion_banner.reload.load_count
        }.by 1
      end
    end

    context 'with event_type: impression' do
      subject do
        RecordPromotionBannerMetric.call(
          event_type: 'impression',
          current_user: nil,
          promotion_banner_id: @promotion_banner.id,
          current_date: Date.current.to_s,
          gtm_blocked: true
        )
      end

      it 'reports impression event' do
        expect { subject }.to change {
          PromotionBannerMetric.where(event_type: 'impression').count
        }.by 1
      end

      it 'increases impression count of promotion_banner' do
        expect { subject }.to change {
          @promotion_banner.reload.impression_count
        }.by 1
      end

      describe 'with no previous impressions' do
        it 'should set the daily_impression_count to 1' do
          expect{ subject }.to change{
            @promotion_banner.reload.daily_impression_count
          }.from(0).to(1)
        end
      end

      describe 'with previous impressions on the same day' do
        let!(:metric) { FactoryGirl.create :promotion_banner_metric, promotion_banner: @promotion_banner,
                        created_at: Time.current, event_type: 'impression' }

        it 'should increment daily_impression_count' do
          expect{ subject }.to change{
            @promotion_banner.reload.daily_impression_count
          }.by(1)
        end
      end

      describe 'with previous impressions on a different day' do
        let!(:metric) { FactoryGirl.create :promotion_banner_metric, promotion_banner: @promotion_banner,
                        created_at: 2.days.ago, event_type: 'impression' }
        before { @promotion_banner.update daily_impression_count: 4 }

        it 'should reset the daily_impression_count to 1' do
          expect{ subject }.to change{
            @promotion_banner.reload.daily_impression_count
          }.to(1)
        end
      end

      context 'when gtm is blocked on front end' do
        it 'records gtm_blocked as true' do
          subject
          expect(PromotionBannerMetric.last.gtm_blocked).to be true
        end
      end
    end

    context 'with event_type: click' do
      subject do
        RecordPromotionBannerMetric.call(
          event_type: 'click',
          user_id: nil,
          promotion_banner_id: @promotion_banner.id,
          current_date: Date.current.to_s
        )
      end

      it 'reports click event' do
        expect { subject }.to change {
          PromotionBannerMetric.where(event_type: 'click').count
        }.by 1
      end

      it 'increases click count of promotion_banner' do
        expect { subject }.to change {
          @promotion_banner.reload.click_count
        }.by 1
      end
    end

  end
end
