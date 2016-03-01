require 'spec_helper'

describe Api::V3::MarketPostsController do
  before do
    @market_cat = FactoryGirl.create :content_category, name: 'market'
  end

  describe 'GET index' do
    before do
      @default_location = FactoryGirl.create :location, city: Location::DEFAULT_LOCATION
      @other_location = FactoryGirl.create :location, city: 'Another City'
      @third_location = FactoryGirl.create :location, city: 'Different Again'
      @user = FactoryGirl.create :user, location: @other_location
      @default_location_contents = FactoryGirl.create_list :content, 3, content_category: @market_cat, 
        locations: [@default_location], published: true
      FactoryGirl.create_list :content, 5, content_category: @market_cat, 
        locations: [@other_location], published: true
      FactoryGirl.create_list :content, 4, content_category: @market_cat, 
        locations: [@third_location], published: true
      @old_post = FactoryGirl.create :content, content_category: @market_cat,
        locations: [@default_location], published: true, pubdate: 40.days.ago
      index
    end

    subject { get :index }

    it 'has 200 status code' do
      subject
      response.code.should eq('200')
    end

    it 'should not include market posts older than 30 days' do
      subject
      assigns(:market_posts).should_not include(@old_post)
    end

    it 'should allow querying by location_id' do
      get :index, format: :json, location_id: @third_location.id
      assigns(:market_posts).select{|c| c.locations.include? @third_location }.count.should eq(assigns(:market_posts).count)
    end

    describe 'querying with location_id=0' do
      subject { get :index, location_id: 0 }

      it 'should filter by Location::DEFAULT_LOCATION' do
        subject
        @default_location_contents.each do |c|
          assigns(:market_posts).should include(c)
        end
        assigns(:market_posts).count.should eq @default_location_contents.count
      end
    end

    describe 'searching' do
      before do
        @content = Content.where(content_category_id: @market_cat).first
      end

      subject { get :index, query: @content.title }

      it 'should return matching content' do
        subject
        assigns(:market_posts).should eq [@content]
      end
    end

    context 'with consumer app specified' do
      before do
        @content = Content.where(content_category_id: @market_cat).first
        @org = @content.organization
        @consumer_app = FactoryGirl.create :consumer_app
        @consumer_app.organizations << @org
        api_authenticate consumer_app: @consumer_app
      end

      it 'should filter results by consumer app\'s organizations' do
        subject
        assigns(:market_posts).should eq([@content])
      end
    end

    context 'not signed in' do
      it 'should respond with market_posts items' do
        subject
        assigns(:market_posts).select{|c| c.content_category_id == @market_cat.id }.count.should eq(assigns(:market_posts).count)
      end

      it 'should respond with market_posts items in any location' do
        subject
        assigns(:market_posts).count.should eq(Content.where(content_category_id: @market_cat.id).
                                               where('pubdate > ?', 30.days.ago).count)
      end
    end

    context 'signed in' do
      before do
        api_authenticate user: @user
      end

      it 'should allow querying by any passed in location_id' do
        get :index, format: :json, location_id: @user.location.id
        assigns(:market_posts).select{|c| c.locations.include? @user.location }.count.should eq(assigns(:market_posts).count)
      end

      it 'should return market_posts items in any location when no location_id passed in' do
        subject
        assigns(:market_posts).count.should eq(Content.where(content_category_id: @market_cat.id).
                                               where('pubdate > ?', 30.days.ago).count)
      end
    end

  end


  describe 'GET show' do
    before do
      @market_post = FactoryGirl.create :content, content_category: @market_cat
    end

    subject { get :show, id: @market_post.id }

    it 'has 200 status code' do
      subject
      response.code.should eq('200')
    end

    it 'appropriately loads the market_posts object' do
      subject
      assigns(:market_post).should eq(@market_post)
    end

    it 'should increment view count' do
      expect{subject}.to change{Content.find(@market_post.id).view_count}.from(0).to(1)
    end

    describe 'can_edit' do
      before do
        @location = FactoryGirl.create :location, city: 'Another City'
        @user = FactoryGirl.create :user, location: @location
        @market_post = FactoryGirl.create :content, content_category: @market_cat
        @market_post.update_attribute(:created_by, @user)
      end

      let(:can_edit) { JSON.parse(response.body)['market_post']['can_edit'] }

      it 'can_edit should be true for the content author' do
        api_authenticate user: @user
        subject 
        can_edit.should == true
      end

      it 'can_edit should false for a different user' do
        @different_user = FactoryGirl.create :user
        api_authenticate user: @different_user
        subject 
        can_edit.should == false
      end

      it 'can_edit should false when a user is not logged in' do
        subject 
        can_edit.should == false
      end
    end

    context 'signed in' do
      before do
        @repo = FactoryGirl.create :repository
        @user = FactoryGirl.create :user
        @consumer_app = FactoryGirl.create :consumer_app, repository: @repo
        @consumer_app.organizations << @market_post.organization
        stub_request(:post, /#{@repo.recommendation_endpoint}/)
        api_authenticate user: @user, consumer_app: @consumer_app
      end

      describe 'record_user_visit' do
        it 'should be called' do
          subject
          expect(WebMock).to have_requested(:post, /#{@repo.recommendation_endpoint}/)
        end
      end
    end

    context 'when requesting app has matching organizations' do
      before do
        organization = FactoryGirl.create :organization
        @market_post.organization = organization
        @market_post.save
        @consumer_app = FactoryGirl.create :consumer_app, organizations: [organization]
        api_authenticate consumer_app: @consumer_app
      end

      it 'should load the content normally' do
        subject
        assigns(:market_post).should == @market_post
      end
    end

    context 'when requesting app DOES NOT HAVE matching organizations' do
      before do
        organization = FactoryGirl.create :organization
        @market_post.organization = organization
        @market_post.save
        @consumer_app = FactoryGirl.create :consumer_app, organizations: []
        api_authenticate consumer_app: @consumer_app
      end

      it { subject; response.status.should eq 204 }
    end

    describe 'for content that isn\'t market' do
      before { @c = FactoryGirl.create :content }

      it 'should respond with nothing' do
        get :show, id: @c.id
        response.code.should eq '204'
      end
    end
       
  end

  describe 'GET contact' do
    describe 'if content isn\'t market' do
      before do
        @content = FactoryGirl.create :content
      end

      it 'should respond with nothing' do
        get :contact, id: @content.id
        response.code.should eq('204')
      end
    end

    describe 'for market category content' do
      before do
        @content = FactoryGirl.create :content, content_category: @market_cat
      end

      it 'has 200 status code' do
        get :contact, id: @content.id
        response.code.should eq '200'
      end
    end

    describe 'for a market channel content' do
      before do
        post_content = FactoryGirl.create :content, content_category: @market_cat
        @market_post = FactoryGirl.create :market_post, content: post_content
      end

      it 'has 200 status code' do
        get :contact, id: @market_post.content.id
        response.code.should eq '200'
      end
    end
  end

  describe 'PUT update' do
    before do
      @user = FactoryGirl.create :user
      @market_post = FactoryGirl.create :market_post
      @attrs_for_update = { 
        title: 'This is a changed title',
        price: 'New low price'
      }
    end

    subject { put :update, id: @market_post.content.id, market_post: @attrs_for_update }

    context 'not signed in' do
      it 'should respond with 401' do
        subject
        response.code.should eq('401')
      end
    end

    context 'signed in' do
      # TODO: once we have created_by, add specs to ensure that only the user who 
      # created the object can update it.
      before do
        api_authenticate user: @user
      end

      it 'should update the market post\'s attributes' do
        expect{subject}.to change{@market_post.reload.cost}.to @attrs_for_update[:price]
      end

      it 'should update the associated content\'s attributes' do
        expect{subject}.to change{@market_post.content.reload.title}.to @attrs_for_update[:title]
      end

      describe 'with invalid parameters' do
        before do
          @attrs_for_update[:title] = ''
        end

        it 'should respond with a 422' do
          subject
          response.code.should eq '422'
        end
      end

      context 'with consumer_app / repository' do
        before do
          @repo = FactoryGirl.create :repository
          @consumer_app = FactoryGirl.create :consumer_app, repository: @repo
          api_authenticate user: @user, consumer_app: @consumer_app
          stub_request(:post, /.*/)
        end

        # because there are so many different external calls and behaviors here, 
        # this is really difficult to test thoroughly, but mocking and checking
        # that the external call is made tests the basics of it.
        it 'should call publish_to_dsp' do
          subject
          # note, OntotextController adds basic auth, hence the complex gsub
          expect(WebMock).to have_requested(:post, /#{@repo.annotate_endpoint.gsub(/http:\/\//,
            "http://#{Figaro.env.ontotext_api_username}:#{Figaro.env.ontotext_api_password}@")}/)
        end
      end

      context 'with extended_reach_enabled true' do
        before do
          @attrs_for_update[:extended_reach_enabled] = true
          @region_location = FactoryGirl.create :location, id: Location::REGION_LOCATION_ID
        end

        it 'should update the market post with locations including REGION_LOCATION_ID' do
          subject
          expect(assigns(:market_post).content.location_ids).to include(Location::REGION_LOCATION_ID)
        end
      end

    end

  end

  describe 'POST create' do
    before do
      @user = FactoryGirl.create :user
    end

    context 'not signed in' do
      it 'should respond with 401' do
        post :create
        response.code.should eq('401')
      end
    end

    context 'signed in' do
      before do
        api_authenticate user: @user
        @basic_attrs = {
          title: 'Fake title',
          content: 'This is a test',
          price: '$99',
          contact_phone: '888-888-8888',
          contact_email: 'fake@email.com',
          locate_address: '300 Main Street Norwich VT 05055',
          preferred_contact_method: 'phone',
          status: 'selling'
        }
      end

      subject { post :create, market_post: @basic_attrs }

      it 'should respond with 201' do
        subject
        response.code.should eq('201')
      end

      it 'should create a market post' do
        expect{subject}.to change{MarketPost.count}.by(1)
      end

      it 'should create an associated content' do
        expect{subject}.to change{Content.count}.by(1)
        (assigns(:market_post).content.present?).should be true
      end

      context 'with consumer_app / repository' do
        before do
          @repo = FactoryGirl.create :repository
          @consumer_app = FactoryGirl.create :consumer_app, repository: @repo
          api_authenticate user: @user, consumer_app: @consumer_app
          stub_request(:post, /.*/)
        end

        # because there are so many different external calls and behaviors here, 
        # this is really difficult to test thoroughly, but mocking and checking
        # that the external call is made tests the basics of it.
        it 'should call publish_to_dsp' do
          subject
          # note, OntotextController adds basic auth, hence the complex gsub
          expect(WebMock).to have_requested(:post, /#{@repo.annotate_endpoint.gsub(/http:\/\//,
            "http://#{Figaro.env.ontotext_api_username}:#{Figaro.env.ontotext_api_password}@")}/)
        end
      end

      describe 'with invalid parameters' do
        before do
          @basic_attrs.delete :title
        end

        it 'should respond with a 500' do
          subject
          response.code.should eq '500'
        end
      end

      context 'with extended_reach_enabled true' do
        before do
          @basic_attrs[:extended_reach_enabled] = true
          @region_location = FactoryGirl.create :location, id: Location::REGION_LOCATION_ID
        end

        it 'should create a market post with locations including REGION_LOCATION_ID' do
          subject
          expect(assigns(:market_post).content.location_ids).to include(Location::REGION_LOCATION_ID)
        end
      end

    end

  end

end
