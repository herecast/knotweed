require 'spec_helper'

describe CampaignsHelper, type: :helper do
  describe "#active_checkbox" do
    it "returns active checkbox attributes" do
      attrs = active_checkbox(true)
      expect(attrs['checked']).to eq 'checked'
    end
  end
end
