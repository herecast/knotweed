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
          sold: market_post.sold,
          images: match_array(market_post.images.collect{|i|
            a_hash_matching({
              id: i.id,
              image_url: i.image_url,
              primary: be(1).or(be(0)),
              width: i.width,
              height: i.height,
              file_extension: i.file_extension
            })
          })
        }))
    end
  end

  describe 'POST /api/v3/market_posts' do
    context "with valid request data" do
      before do
        ContentCategory.create(name: :market)
      end

      let(:valid_params) {
        {
          title: 'Test',
          content: 'Body'
        }
      }

      subject{ post("/api/v3/market_posts", {market_post: valid_params}, auth_headers) }

      it 'responds with 201' do
        subject
        expect(response.status).to eql 201
      end

      it 'creates a record' do
        expect{ subject }.to change{
          MarketPost.count
        }.by(1)
      end

      it 'returns a content_id in json' do
        # this is needed by listserv workflow
        subject
        expect(response_json[:market_post][:content_id]).to eql MarketPost.last.content.id
      end
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
    let(:market_category) { FactoryGirl.create :content_category, name: 'market' }

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
        created_at: a_kind_of(String),
        updated_at: a_kind_of(String),
        image_url: an_instance_of(String).or(be_nil),
        contact_phone: a_kind_of(String).or(be_nil),
        contact_email: a_kind_of(String).or(be_nil),
        preferred_contact_method: a_kind_of(String).or(be_nil),
        images: be_an(Array),
        sold: be_boolean
      )
    end

    it 'returns the correct number of total results' do
      get '/api/v3/market_posts', request_params.merge(per_page: 3)
      collection_count = response_json[:market_posts].count
      total_count = response_json[:meta][:total]
      expect(total_count).to be > collection_count
    end

    context 'searching with a modifier param' do

      before do
        @blue_post = FactoryGirl.create :market_post, title: 'Blue Color'
        @red_post = FactoryGirl.create :market_post, title: 'Red Color'
        @green_post = FactoryGirl.create :market_post, title: 'Green Color'
        @no_color_post = FactoryGirl.create :market_post, title: 'No color in this post'
      end
      
      it 'responds to requrests using the "AND" modifier param' do
        get '/api/v3/market_posts', request_params.merge(query: 'color, post', query_modifier: "AND")
        expect(response_json[:market_posts].count).to eq 1
        expect(response_json[:market_posts].first[:title]).to eq @no_color_post.title
      end

      it 'responds to requests using the "OR" modifier param' do
        get '/api/v3/market_posts', request_params.merge(query: 'Blue, Green, Red', query_modifier: "OR")
        expect(response_json[:market_posts].count).to eq 3
      end
      
      it 'responds to requests using the "Match Phrase" modifier param' do
        get '/api/v3/market_posts', request_params.merge(query: "Blue Color", query_modifier: "Match Phrase")
        expect(response_json[:market_posts].count).to eq 1
        expect(response_json[:market_posts].first[:title]).to eq @blue_post.title
      end

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

        context 'when user owns a market post' do
          let!(:owned_by_user) {
            FactoryGirl.create :market_post,
              title: 'Owned by user Post',
              created_by: user,
              locations: [user.location]
          }

          it 'returns can_edit=true for that record' do
            subject
            post = response_json[:market_posts].find do |h|
              h[:id].eql? owned_by_user.id
            end

            expect(post[:can_edit]).to be true
          end
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
        get "/api/v3/market_posts/#{market_post.content.id}"
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
        get "/api/v3/market_posts/#{market_post.content.id}"
        expect(response_json[:market_post][:can_edit]).to eql false
      end

      it 'does not allow a user to send an update' do
        put "/api/v3/market_posts/#{market_post.content.id}", { news: put_params }, auth_headers
        expect(response.status).to eql 403
      end
      
    end

    context 'when no market post object exists for content' do
      let(:listserv_content) { FactoryGirl.create :content, content_category: market_cat }
      
      before do
        allow_any_instance_of(Ability).to receive(:can?).with(:manage, listserv_content).and_return(true)
      end

      it 'returns false' do
        get "/api/v3/market_posts/#{listserv_content.id}"
        expect(response_json[:market_post][:can_edit]).to eq false
      end

    end

  end

  describe 'PUT api/v3/market_post/:id' do
    let!(:market_cat) { FactoryGirl.create :market_category, name: 'market' }
    let!(:user) { FactoryGirl.create :user }
    let!(:market_post) { FactoryGirl.create :market_post, sold: false }
    let(:content) { FactoryGirl.create :content }
    let(:auth_headers) { auth_headers_for(user) }
    let(:market_post_params) do
      { market_post: { 
          contact_email: user.email, 
          contact_phone: user.contact_phone, 
          content: market_post.content,
          sold: true,
          title: "Sample market post with contnet", 
          address: '123 fake', 
          city: 'still needed?', 
          zip: '19143'}
      }
    end
    context 'marking a post as sold' do

      before do
        allow_any_instance_of(Ability).to receive(:can?).with(:manage, market_post.content).and_return(true)
      end

      context 'when content has an associated market post' do
        it 'updates sold to true on the market post' do
          put "/api/v3/market_posts/#{market_post.content.id}", market_post_params, auth_headers
          expect(response_json[:market_post][:sold]).to eq true
        end
      end
    end
  end
end
