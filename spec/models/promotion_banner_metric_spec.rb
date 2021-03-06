# frozen_string_literal: true

# == Schema Information
#
# Table name: promotion_banner_metrics
#
#  id                  :bigint(8)        not null, primary key
#  promotion_banner_id :integer
#  event_type          :string
#  content_id          :integer
#  select_method       :string
#  select_score        :float
#  user_id             :integer
#  location            :string
#  page_url            :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  gtm_blocked         :boolean
#  user_agent          :string
#  user_ip             :string
#  page_placement      :string
#  client_id           :string
#  location_id         :integer
#  load_time           :float
#  location_confirmed  :boolean          default(FALSE)
#
# Indexes
#
#  index_promotion_banner_metrics_on_content_id           (content_id)
#  index_promotion_banner_metrics_on_created_at           (created_at)
#  index_promotion_banner_metrics_on_event_type           (event_type)
#  index_promotion_banner_metrics_on_promotion_banner_id  (promotion_banner_id)
#

require 'rails_helper'

RSpec.describe PromotionBannerMetric, type: :model do
  it { is_expected.to belong_to :user }
  it { is_expected.to belong_to :location }

  context 'when no promotion_banner_id' do
    it 'PromotionBannerMetric is not valid' do
      promotion_banner_metric = FactoryGirl.build :promotion_banner_metric, promotion_banner_id: nil
      expect(promotion_banner_metric).to_not be_valid
    end
  end

  context 'when promotion_banner_id is present' do
    it 'PromotionBannerMetric is valid' do
      promotion_banner = FactoryGirl.create :promotion_banner
      promotion_banner_metric = FactoryGirl.build :promotion_banner_metric, promotion_banner_id: promotion_banner.id
      expect(promotion_banner_metric).to be_valid
    end
  end
end
