# frozen_string_literal: true

require 'spec_helper'

describe Api::V3::MetricsSerializer do
  let(:org) { FactoryGirl.create :organization }
  let(:context_for_serializer) { { start_date: Date.yesterday, end_date: Date.today } }

  subject do
    JSON.parse(Api::V3::MetricsSerializer.new(
      org,
      root: false,
      context: context_for_serializer
    ).to_json)
  end

  it 'should successfully serialize the metrics for the object' do
    expect(subject['id']).to eq org.id
  end

  %w[
    promo_click_thru_count
    view_count
    comment_count
    daily_view_counts
    daily_promo_click_thru_counts
  ].each do |k|
    it "should serialize `#{k}`" do
      expect(subject.keys).to include k
    end
  end
end
