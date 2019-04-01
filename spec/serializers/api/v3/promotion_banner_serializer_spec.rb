# frozen_string_literal: true

require 'spec_helper'

describe Api::V3::PromotionBannerSerializer do
  let(:promotion_banner) { FactoryGirl.create :promotion_banner }
  subject { JSON.parse(Api::V3::PromotionBannerSerializer.new(promotion_banner, root: false).to_json) }

  it { expect(subject['title']).to eq promotion_banner.promotion.content.title }
  it { expect(subject['pubdate']).to eq promotion_banner.promotion.content.pubdate.strftime('%FT%T%:z') }
  it { expect(subject['image_url']).to eq promotion_banner.banner_image.url }
  it { expect(subject['content_type']).to eq 'promotion_banner' }
  it { expect(subject['description']).to eq promotion_banner.promotion.description }
end
