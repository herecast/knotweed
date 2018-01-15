require 'rails_helper'

RSpec.describe UpdateDigestMetrics do
  before do
    allow(Figaro.env).to receive(:mailchimp_api_host).and_return("test.com")
    allow(Figaro.env).to receive(:mailchimp_api_key).and_return("test.key")
  end
  let(:auth) { ["user", Figaro.env.mailchimp_api_key] }
  let(:mc_base_url) { Figaro.env.mailchimp_api_host.to_s + '/3.0' }

  context 'Given a digest with campaign data on mailchimp' do
    let(:digest) {
      FactoryGirl.create :listserv_digest,
        mc_campaign_id: 'kdsksd',
        emails_sent: 0,
        opens_total: 0,
        link_clicks: {},
        last_mc_report: nil,
        promotion_ids: [
          FactoryGirl.create(:promotion_banner, redirect_url: 'http://promoabc.test').promotion.id,
          FactoryGirl.create(:promotion_banner, redirect_url: 'http://promo76.test').promotion.id
        ]
    }
    let(:emails_sent) { 200 }
    let(:opens_total) { 186 }
    let(:click_map) {
      {
        "http://promoabc.test" => "40",
        "http://promo76.test" => "50"
      }
    }

    before do
      # first request (reports/campaign_id)
      stub_request(:get,
        "https://#{mc_base_url}/reports/#{digest.mc_campaign_id}"
      ).with(
        basic_auth: auth,
        headers: {
          "Content-Type" => 'application/json',
          "Accept" => 'application/json'
        }
      ).to_return(
        status: 200,
        headers: {
          "Content-Type" => 'application/json',
        },
        body: {
          emails_sent: emails_sent,
          opens: {
            opens_total: opens_total
          }
        }.to_json
      )

      # second request (reports/campaign_id/click-details)
      stub_request(:get,
        "https://#{mc_base_url}/reports/#{digest.mc_campaign_id}/click-details"
      ).with(
        basic_auth: auth,
        headers: {
          "Content-Type" => 'application/json',
          "Accept" => 'application/json'
        }
      ).to_return(
        status: 200,
        headers: {
          "Content-Type" => 'application/json',
        },
        body: {
          urls_clicked: click_map.map do |url, clicks|
            { url: url, total_clicks: clicks.to_i}
          end
        }.to_json
      )
    end

    subject { described_class.call(digest) }

    it 'sets the expected values on the digest' do
      Timecop.freeze do
        subject
        digest.reload
        expect(digest.emails_sent).to eql emails_sent
        expect(digest.opens_total).to eql opens_total
        expect(digest.link_clicks).to eql click_map
        # convert to iso8601 for comparison to normalize precision
        expect(digest.last_mc_report.iso8601).to eql Time.current.iso8601
      end
    end
  end
end
