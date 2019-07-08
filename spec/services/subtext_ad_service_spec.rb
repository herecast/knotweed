# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SubtextAdService do
  # stub config so we don't need env vars
  let(:config) { {
      public_key: 'fake-public-key',
      secret: 'fake-secret',
      host: 'http://subtextads.com/fake/host'
  } }

  before { allow(SubtextAdService).to receive(:config).and_return(config) }

  describe '#create(campaign)' do
    let(:campaign) { FactoryGirl.create :content, :campaign }
    subject { SubtextAdService.create(campaign) }

    describe 'when the request succeeds' do
      before do
        allow(HTTParty).to receive(:post).with("#{config[:host]}/campaigns", any_args)
          .and_return({ '_id' => 'fake-id', 'client' => 'fake-client-id' })
      end

      it 'should submit a POST request to campaigns address' do
        expect(HTTParty).to receive(:post).with("#{config[:host]}/campaigns", any_args)
        subject
      end

      it 'should submit a POST request with auth headers' do
        allow(SubtextAdService).to receive(:encoded_payload).and_return('fake-payload')
        headers = {
          'Content-Type': 'application/json',
          PUBLIC_KEY: config[:public_key],
          Authorization: "Bearer fake-payload"
        }
        expect(HTTParty).to receive(:post).with(anything,
            hash_including(headers: headers))
        subject
      end

      describe 'when organization already has ad_service_id' do
        before { campaign.organization.update ad_service_id: 'fake123456' }

        it 'should submit a POST request with correct body' do
          body = {
            title: campaign.title,
            promotionType: campaign.ad_promotion_type,
            campaignStart: campaign.ad_campaign_start,
            campaignEnd: campaign.ad_campaign_end,
            maxImpressions: campaign.ad_max_impressions,
            invoicedAmount: campaign.ad_invoiced_amount,
            client: campaign.organization.ad_service_id
          }
          expect(HTTParty).to receive(:post).with(anything,
                             hash_including(body: body.to_json))
          subject
        end

        it 'should update the campaign with the returned ID from SubtextAdService' do
          expect{subject}.to change{campaign.ad_service_id}.to('fake-id')
        end
      end

      describe 'when organization does not have ad_service_id' do
        before { campaign.organization.update ad_service_id: nil }

        it 'should submit a POST request with correct body' do
          body = {
            title: campaign.title,
            promotionType: campaign.ad_promotion_type,
            campaignStart: campaign.ad_campaign_start,
            campaignEnd: campaign.ad_campaign_end,
            maxImpressions: campaign.ad_max_impressions,
            invoicedAmount: campaign.ad_invoiced_amount,
            clientAttributes: {
              name: campaign.organization.name,
              adContactNickname: campaign.organization.ad_contact_nickname,
              adContactFullname: campaign.organization.ad_contact_fullname
            }
          }
          expect(HTTParty).to receive(:post).with(anything,
                             hash_including(body: body.to_json))
          subject
        end

        it 'should update the organization with the returned client ID' do
          expect{subject}.to change{campaign.organization.ad_service_id}.to('fake-client-id')
        end
      end
    end

  end

  describe '#update(campaign)' do
    let(:campaign) { FactoryGirl.create :content, :campaign }
    before { campaign.organization.update ad_service_id: 'fake-ad-service-id' }

    subject { SubtextAdService.update(campaign) }

    describe 'when the request succeeds' do
      before do
        allow(HTTParty).to receive(:put).with("#{config[:host]}/campaigns/#{campaign.ad_service_id}", any_args)
          .and_return({ '_id' => 'fake-id' })
      end

      it 'should submit a PUT request to correct URL' do
        expect(HTTParty).to receive(:put).with("#{config[:host]}/campaigns/#{campaign.ad_service_id}", any_args)
        subject
      end

      it 'should submit a PUT request with correct body' do
       body = {
         title: campaign.title,
          promotionType: campaign.ad_promotion_type,
          campaignStart: campaign.ad_campaign_start,
          campaignEnd: campaign.ad_campaign_end,
          maxImpressions: campaign.ad_max_impressions,
          invoicedAmount: campaign.ad_invoiced_amount,
          client: campaign.organization.ad_service_id
        }
        expect(HTTParty).to receive(:put).with(anything,
                           hash_including(body: body.to_json))
        subject
      end
    end
  end

  describe '#add_creative(creative)' do
    let(:campaign) { FactoryGirl.create :content, :campaign }
    let(:creative) { FactoryGirl.create :promotion_banner, content: campaign}
    subject { SubtextAdService.add_creative(creative) }

    describe 'when the request succeeds' do
      before do
        allow(HTTParty).to receive(:post).with("#{config[:host]}/creatives", any_args)
          .and_return({ '_id' => 'fake-id' })
      end

      it 'should submit a POST request to creatives address' do
        expect(HTTParty).to receive(:post).with("#{config[:host]}/creatives", any_args)
        subject
      end

      it 'should submit a POST request with correct body' do
        body = {
          redirectUrl: creative.redirect_url,
          imageUrl: creative.banner_image.url,
          description: creative.promotion.description,
          creativeStart: creative.campaign_start,
          creativeEnd: creative.campaign_end,
          promotionType: creative.promotion_type,
          maxImpressions: creative.max_impressions,
          locationId: creative.location_id,
          campaign: campaign.ad_service_id
        }
        expect(HTTParty).to receive(:post).with(anything,
                                          hash_including(body: body.to_json))
        subject
      end

      it 'should update the creative with the returned ID from SubtextAdService' do
        expect{subject}.to change{creative.ad_service_id}.to('fake-id')
      end
    end
  end

  describe "#update_creative(creative)" do
    let(:campaign) { FactoryGirl.create :content, :campaign }
    let(:creative) { FactoryGirl.create :promotion_banner, content: campaign}
    subject { SubtextAdService.update_creative(creative) }

    describe 'when the request succeeds' do
      before do
        allow(HTTParty).to receive(:put).with("#{config[:host]}/creatives/#{creative.ad_service_id}", any_args)
          .and_return({ '_id' => 'fake-id' })
      end

      it 'should submit a PUT request to the creatives address' do
        expect(HTTParty).to receive(:put).with("#{config[:host]}/creatives/#{creative.ad_service_id}", any_args)
        subject
      end

      it 'should submit a PUT request with the correct body' do
        body = {
          redirectUrl: creative.redirect_url,
          imageUrl: creative.banner_image.url,
          description: creative.promotion.description,
          creativeStart: creative.campaign_start,
          creativeEnd: creative.campaign_end,
          promotionType: creative.promotion_type,
          maxImpressions: creative.max_impressions,
          locationId: creative.location_id,
          campaign: campaign.ad_service_id
        }
        expect(HTTParty).to receive(:put).with(anything,
                                          hash_including(body: body.to_json))
        subject
      end
    end
  end
end
