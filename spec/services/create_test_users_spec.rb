require 'spec_helper'

describe CreateTestUsers do
  before do
    FactoryGirl.create :location
    FactoryGirl.create :consumer_app
    @rake_factory = CreateTestUsers.new
  end

  describe '#create_user' do
    it "increases user count by 1" do
      expect(STDOUT).to receive(:puts).once
      expect{ @rake_factory.create_user }.to change { User.count }.by 1
    end
  end

  describe '#create_org' do
    it "increases organization count by 1" do
      expect(STDOUT).to receive(:puts).once
      expect{ @rake_factory.create_org }.to change { Organization.count }.by 1
    end
  end
end