# frozen_string_literal: true

# == Schema Information
#
# Table name: promotion_banner_reports
#
#  id                     :bigint(8)        not null, primary key
#  promotion_banner_id    :bigint(8)
#  report_date            :datetime
#  impression_count       :bigint(8)
#  click_count            :bigint(8)
#  total_impression_count :bigint(8)
#  total_click_count      :bigint(8)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  load_count             :integer
#
# Indexes
#
#  index_promotion_banner_reports_on_promotion_banner_id  (promotion_banner_id)
#  index_promotion_banner_reports_on_report_date          (report_date)
#

require 'spec_helper'

describe PromotionBannerReport, type: :model do
  before { @promotion_banner_report = FactoryGirl.build :promotion_banner_report }
  subject { @promotion_banner_report }
  it { is_expected.to be_valid }

  describe 'daily_revenue' do
    before do
      @promotion_banner = FactoryGirl.create :promotion_banner
      @promotion_banner_report = FactoryGirl.create :promotion_banner_report
      @promotion_banner.promotion_banner_reports << @promotion_banner_report
    end

    subject { @promotion_banner_report.daily_revenue }

    context 'when no price details present' do
      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when parent promotion banner has daily cost' do
      before do
        @cost_per_day = 6.43
        @promotion_banner.update_attribute :cost_per_day, @cost_per_day
      end

      it 'returns cost per day' do
        expect(subject).to eq @cost_per_day
      end
    end

    context 'when parent promotion banner has impression cost' do
      before do
        @cost_per_impression = 0.15
        @impression_count = 5
        @promotion_banner.update_attribute :cost_per_impression, @cost_per_impression
        @promotion_banner_report.update_attribute :impression_count, @impression_count
      end

      it 'returns cost_per_impression * impression_count' do
        expect(subject).to eq @cost_per_impression * @impression_count
      end
    end
  end
end
