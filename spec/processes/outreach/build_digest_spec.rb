require 'spec_helper'

RSpec.describe Outreach::BuildDigest do

  describe "::call" do
    let(:listserv) { FactoryGirl.create :listserv }

    subject { Outreach::BuildDigest.call(listserv) }

    it "returns unpersisted instance of ListservDigest" do
      digest = subject
      expect(digest.class).to eq ListservDigest
      expect(digest.persisted?).to be false
    end
  end
end