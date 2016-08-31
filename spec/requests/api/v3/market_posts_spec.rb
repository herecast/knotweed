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

    it 'returns all public attributes in correct schema' do
      get "/api/v3/market_posts/#{market_post.content.id}.json", {}, headers
      expect(response_json).to match(
        market_post: a_hash_including({
          id: market_post.id,
          title: market_post.content.sanitized_title,
          price: market_post.cost,
          content: market_post.content.sanitized_content,
          content_id: market_post.content.id,
          published_at: market_post.pubdate.try(:iso8601),
          locate_address: market_post.locate_address,
          can_edit: be_boolean,
          has_contact_info: be_boolean,
          my_town_only: be_boolean,
          author_name: a_kind_of(String).or(be_nil),
          organization_id: market_post.content.organization_id,
          updated_at: market_post.content.updated_at.try(:iso8601),
          image_url: an_instance_of(String).or(be_nil),
          contact_phone: market_post.contact_phone,
          contact_email: market_post.contact_email,
          preferred_contact_method: market_post.preferred_contact_method,
          images: match_array(market_post.images.collect{|i|
            a_hash_matching({
              id: i.id,
              image_url: i.image_url,
              primary: be(1).or(be(0))
            })
          })
        })
      )
    end
  end

  describe 'GET /api/v3/market_posts', elasticsearch: true do
    before do
      @loc1 = FactoryGirl.create :location
      @loc2 = FactoryGirl.create :location
      @mps_loc1 = FactoryGirl.create_list :market_post, 3, locations: [@loc1]
      @mps_loc2 = FactoryGirl.create_list :market_post, 3, locations: [@loc2]
      @mp_mto_loc1 = FactoryGirl.create :market_post, locations: [@loc1], my_town_only: true
      @mp_mto_loc2 = FactoryGirl.create :market_post, locations: [@loc2], my_town_only: true
    end

    let(:request_params) { {} }
    let(:user) { FactoryGirl.create :user, location: @loc1 }

    subject { get '/api/v3/market_posts', request_params.merge({ format: :json }) }

    it 'matches expected output json' do
      subject

      expect(response_json[:market_posts][0]).to match(
        id: a_kind_of(Integer),
        title: a_kind_of(String),
        price: a_kind_of(String),
        content: a_kind_of(String),
        content_id: a_kind_of(Integer),
        published_at: a_kind_of(String),
        locate_address: a_kind_of(String),
        can_edit: be_boolean,
        has_contact_info: be_boolean,
        my_town_only: be_boolean,
        author_name: a_kind_of(String),
        organization_id: a_kind_of(Integer),
        updated_at: a_kind_of(String),
        image_url: an_instance_of(String).or(be_nil),
        contact_phone: a_kind_of(String).or(be_nil),
        contact_email: a_kind_of(String).or(be_nil),
        preferred_contact_method: a_kind_of(String).or(be_nil),
        images: be_an(Array)
      )
    end

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

  describe 'can_edit' do
    let!(:market_cat) { FactoryGirl.create :content_category, name: 'market' }
    let!(:user) { FactoryGirl.create :user }
    let(:market_post) { FactoryGirl.create :market_post }

    context 'when ability allows for edit' do
      before do
        allow_any_instance_of(Ability).to receive(:can?).with(:manage, market_post.content).and_return(true)
      end

      it "returns true" do
        get "/api/v3/market_posts/#{market_post.id}"
        expect(response_json[:market_post][:can_edit]).to eql true
      end
    end

    context 'when ability does not allow to edit' do
      let(:other_user) { FactoryGirl.create :user } 
        let(:put_params) do
          {
            title: 'blerb',
            content: Faker::Lorem.paragraph,
            organization_id: nil,
            published_at: Time.current
          }
        end
      let(:auth_headers) { auth_headers_for(other_user) }

      it "returns false" do
        allow_any_instance_of(Ability).to receive(:can?).with(:manage, market_post.content).and_return(false)
        get "/api/v3/market_posts/#{market_post.id}"
        expect(response_json[:market_post][:can_edit]).to eql false
      end

      it 'does not allow a user to send an update' do
        put "/api/v3/market_posts/#{market_post.id}", { news: put_params }, auth_headers
        expect(response.status).to eql 403
      end
      
    end
  end
end
