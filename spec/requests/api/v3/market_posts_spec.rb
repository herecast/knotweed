require 'spec_helper'

describe 'Market Posts', type: :request do
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
      market_post.content.save!
      allow_any_instance_of(ConsumerApp).to receive(:organizations).and_return([organization])
    end

    # Maybe we can change this later to assert against the whole json schema
    it 'should contain orgainzation_id' do
      get "/api/v3/market_posts/#{market_post.content.id}.json", {}, headers

      expect(response_json['market_post']['organization_id']).to eql organization.id
    end
  end

  describe 'GET /api/v3/market_posts' do
    before do
      @loc1 = FactoryGirl.create :location
      @loc2 = FactoryGirl.create :location
      @mps_loc1 = FactoryGirl.create_list :market_post, 3, locations: [@loc1]
      @mps_loc2 = FactoryGirl.create_list :market_post, 3, locations: [@loc2]
      @mp_mto_loc1 = FactoryGirl.create :market_post, locations: [@loc1], my_town_only: true
      @mp_mto_loc2 = FactoryGirl.create :market_post, locations: [@loc2], my_town_only: true
      index
    end

    let(:request_params) { {} }
    let(:user) { FactoryGirl.create :user, location: @loc1 }

    subject { get '/api/v3/market_posts', request_params.merge({ format: :json }) }

    context 'as signed in user' do
      subject { get '/api/v3/market_posts', request_params.merge({ format: :json }), auth_headers }

      describe 'default request (no params)' do
        it 'should return all market posts without `my_town_only`' do
          subject
          expect(assigns(:market_posts)).to match_array((@mps_loc1+@mps_loc2+[@mp_mto_loc1]).map{|mp| mp.content})
        end

        it 'should not return `my_town_only` market posts from other towns' do
          subject
          expect(assigns(:market_posts)).to_not include @mp_mto_loc2.content
        end
      end

      describe 'searching for the user\'s location' do
        let(:request_params) { { location_id: user.location.id } } # @loc1

        it 'should respond with all market posts from that location (including `my_town_only`)' do
          subject
          expect(assigns(:market_posts)).to match_array((@mps_loc1+[@mp_mto_loc1]).map{|mp| mp.content})
        end
      end

      describe 'searching for a different location' do
        let(:request_params) { { location_id: @loc2.id } }

        it 'should not include `my_town_only` market posts' do
          subject
          expect(assigns(:market_posts)).to_not include @mp_mto_loc2.content
        end

        it 'should respond with non `my_town_only` market posts in that location' do
          subject
          expect(assigns(:market_posts)).to match_array(@mps_loc2.map{|mp| mp.content})
        end
      end
    end
  end
end
