require 'spec_helper'

RSpec.describe 'Rewrites endpoints' do
  describe 'GET /api/v3/rewrites' do
    before do
      @rewrite = FactoryGirl.create :rewrite
    end

    context "when no query" do
      subject { get '/api/v3/rewrites' }

      it 'returns empty object' do
        subject
        expect(JSON.parse(response.body)).to eq({})
      end
    end

    context "when query yields no results" do
      subject { get '/api/v3/rewrites?query=nada' }

      it 'returns empty object' do
        subject
        expect(JSON.parse(response.body)).to eq({})
      end
    end

    context "when query matches rewrite" do
      let(:expected_response) { {
        rewrite: {
          source: @rewrite.source,
          destination: @rewrite.destination
        }
      }.to_json }

      subject { get "/api/v3/rewrites?query=#{@rewrite.source}" }

      it 'returns rewrite' do
        subject
        expect(response.body).to eq(expected_response)
      end
    end
  end
end