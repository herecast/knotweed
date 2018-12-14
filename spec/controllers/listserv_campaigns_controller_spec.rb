require 'spec_helper'

describe ListservCampaignsController do
  let(:listserv) { FactoryGirl.create(:listserv) }

  before do
    sign_in FactoryGirl.create(:admin)
  end

  describe 'POST create' do
    let(:raw_campaign_attrs)   { FactoryGirl.attributes_for(:campaign) }
    let(:string_community_ids) { raw_campaign_attrs[:community_ids].map(&:to_s) }
    let(:campaign_attrs)       { raw_campaign_attrs.merge(community_ids: string_community_ids) }
    subject                    { post :create, params: { listserv_id: listserv, campaign: campaign_attrs }, format: :js }

    it 'adds a campaign record' do
      expect { subject }.to change { Campaign.count }.by(1)
    end

    it 'returns a success status code' do
      subject
      expect(response.code).to eq '200'
    end

    context 'with invalid params' do
      let(:invalid_attrs) { campaign_attrs.except :community_ids }
      subject             { post :create, params: { listserv_id: listserv, campaign: invalid_attrs }, format: :js }

      it 'adds no campaign record' do
        expect { subject }.not_to change { Campaign.count }
      end

      it 'returns a failure status code' do
        subject
        expect(response.code).to eq '422'
      end
    end
  end

  describe 'PUT update' do
    let(:new_sponsor) { 'new sponsor' }
    let(:patch_attrs) { { sponsored_by: new_sponsor } }
    let(:campaign)    { FactoryGirl.create(:campaign) }
    let(:listserv)    { campaign.listserv }
    subject           { put :update, params: { listserv_id: listserv, id: campaign, campaign: patch_attrs }, format: :js }

    it 'modifies the given record' do
      expect { subject }.to change { campaign.reload.sponsored_by }
      expect(campaign.sponsored_by).to eq new_sponsor
    end

    it 'returns a success status code' do
      subject
      expect(response.code).to eq '200'
    end

    context 'with invalid params' do
      let(:invalid_attrs) { patch_attrs.merge(community_ids: ['']) }
      subject             { put :update, params: { listserv_id: listserv, id: campaign, campaign: invalid_attrs }, format: :js }

      it 'leaves the given record intact' do
        expect { subject }.not_to change { campaign.reload.sponsored_by }
      end

      it 'returns a failure status code' do
        subject
        expect(response.code).to eq '422'
      end
    end
  end

  describe 'DELETE destroy' do
    let!(:campaign) { FactoryGirl.create(:campaign) }
    let(:listserv)  { campaign.listserv }
    subject         { delete :destroy, params: { listserv_id: listserv, id: campaign }, format: :js }

    it 'removes the campaign record' do
      expect { subject }.to change { Campaign.count }.by(-1)
    end

    it 'returns a success status code' do
      subject
      expect(response.code).to eq '200'
    end
  end
end
