require 'spec_helper'

RSpec.describe 'Similar Contents Endpoints', type: :request do

  describe 'GET /api/v3/contents/:content_id/similar_content', elasticsearch: true do
    let(:content) { FactoryGirl.create :content }
    let!(:sim_content) do
      FactoryGirl.create :content,
                         title: content.title,
                         raw_content: content.sanitized_content,
                         origin: Content::UGC_ORIGIN
    end

    subject do
      get "/api/v3/contents/#{content.id}/similar_content", params: { id: content.id }
    end

    it 'has 200 status code' do
      subject
      expect(response.status).to eq 200
    end

    it 'responds with relation of similar content' do
      subject
      response_content_ids = response_json[:similar_content].map do |sc|
        sc[:id]
      end
      expect(response_content_ids).to match_array([sim_content.id])
    end
  end
end
