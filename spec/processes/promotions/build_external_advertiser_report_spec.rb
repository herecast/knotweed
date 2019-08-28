require 'spec_helper'

RSpec.describe Promotions::BuildExternalAdvertiserReport do
  describe "::call" do
    before do
      @organization = FactoryGirl.create :organization
      @campaign = FactoryGirl.create :content, :campaign,
        organization: @organization
      pdf_double = double(pdf_from_string: 'funky-pdf-string')
      allow(WickedPdf).to receive(:new).and_return(pdf_double)
    end

    let(:args) do
      {
        organization: @organization,
        campaigns: [@campaign]
      }
    end

    subject { Promotions::BuildExternalAdvertiserReport.call(args) }

    it "creates external advertiser report connected to Organization" do
      expect{ subject }.to change{
        @organization.reload.external_advertiser_reports.count
      }.by 1
    end

    it "returns hash with pdf and pdf name" do
      expected_hash = { name: an_instance_of(String), pdf: an_instance_of(String) }
      expect(subject).to include expected_hash
    end
  end
end