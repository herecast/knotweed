require 'rails_helper'

RSpec.describe GatherFeedRecords, elasticsearch: true do

  describe "::call" do
    before do
      @content = FactoryGirl.create :content, :news
      @organization = FactoryGirl.create :organization
      @contents = Content.search('*', { load: false })
    end

    let(:params) do
      {}
    end

    subject do
      GatherFeedRecords.call(
        params: params,
        current_ability: nil,
        requesting_app: nil,
        current_user: nil
      )
    end

    it "returns restructured payload" do
      response = subject
      expect(response[:feed_items][0].to_json).to include_json({
        model_type: "feed_content",
        id: @content.id,
        carousel: nil,
        organization: nil
      })
      expect(response[:feed_items][0].feed_content.id).to eq @content.id
    end
  end
end