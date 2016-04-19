require 'spec_helper'

describe 'Market Posts', type: :request do
  let(:market_cat) { FactoryGirl.create :content_category, name: 'market' }
  let(:user) { FactoryGirl.create :user }
  let(:auth_headers) { auth_headers_for(user) }
  let(:consumer_app) { FactoryGirl.create :consumer_app }

  describe 'GET /api/v3/market_posts/:id' do
    let(:organization) { FactoryGirl.create :organization, name: "TESTORG" }
    let(:market_post) { FactoryGirl.create :market_post }
    let(:headers) { {
      'ACCEPT' => 'application/json',
      'Consumer-App-Uri' => consumer_app.uri
    } }

    before do
      market_post.content.organization= organization
      market_post.content.content_category_id = market_cat.id
      market_post.content.save!
      allow_any_instance_of(ConsumerApp).to receive(:organizations).and_return([organization])
    end

    # Maybe we can change this later to assert against the whole json schema
    it 'should contain orgainzation_id' do
      get "/api/v3/market_posts/#{market_post.content.id}.json", {}, headers

      expect(response_json['market_post']['organization_id']).to eql organization.id
    end
  end
end
