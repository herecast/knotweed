require 'rails_helper'

RSpec.describe GatherFeedRecords, elasticsearch: true do

  describe "::call" do
    before do
      @content = FactoryGirl.create :content, :news
    end

    let(:params) do
      {}
    end

    subject do
      GatherFeedRecords.call(
        params: params,
        requesting_app: nil,
        current_user: nil
      )
    end

    it "returns restructured payload" do
      response = subject
      expect(response[:records][0].to_json).to include_json({
        model_type: "content",
        id: @content.id
      })
      expect(response[:records][0].content.id).to eq @content.id
    end

    it "alerts product team of new content" do
      allow(BackgroundJob).to receive(:perform_later).with('AlertProductTeamOfNewContent').and_return true
      expect(BackgroundJob).to receive(:perform_later).with('AlertProductTeamOfNewContent', 'call', any_args)
      subject
    end
  end
end
