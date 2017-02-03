require 'spec_helper'

describe Api::V3::MarketPostsController, :type => :controller do
  before do
    @market_cat = FactoryGirl.create :content_category, name: 'market'
  end

  describe 'GET index', elasticsearch: true do
    before do
      @default_location = FactoryGirl.create :location, city: Location::DEFAULT_LOCATION
      @other_location = FactoryGirl.create :location, city: 'Another City'
      @third_location = FactoryGirl.create :location, city: 'Different Again'
      @user = FactoryGirl.create :user, location: @other_location
      @default_location_content = FactoryGirl.create :content, content_category: @market_cat, 
        locations: [@default_location], published: true
      FactoryGirl.create :content, content_category: @market_cat, 
        locations: [@other_location], published: true
      FactoryGirl.create :content, content_category: @market_cat, 
        locations: [@third_location], published: true
      @old_post = FactoryGirl.create :content, content_category: @market_cat,
        locations: [@default_location], published: true, pubdate: 40.days.ago
    end

    subject { get :index }

    it 'has 200 status code' do
      subject
      expect(response.code).to eq('200')
    end

    it 'should not include market posts older than 30 days' do
      subject
      expect(assigns(:market_posts)).not_to include(@old_post)
    end

    it 'should allow querying by location_id' do
      get :index, format: :json, location_id: @third_location.id
      expect(assigns(:market_posts).select{|c| c.locations.include? @third_location }.count).to eq(assigns(:market_posts).count)
    end

    describe 'querying with location_id=0' do
      subject { get :index, location_id: 0 }

      it 'should filter by Location::DEFAULT_LOCATION' do
        subject
        expect(assigns(:market_posts)).to match_array [@default_location_content]
      end
    end

    describe 'searching' do
      before do
        @content = Content.where(content_category_id: @market_cat).first
      end

      subject { get :index, query: @content.title }

      it 'should return matching content' do
        subject
        expect(assigns(:market_posts)).to match_array [@content]
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
        expect(assigns(:market_posts)).to match_array([@content])
      end
    end

    context 'not signed in' do
      it 'should respond with market_posts items' do
        subject
        expect(assigns(:market_posts).select{|c| c.content_category_id == @market_cat.id }.count).to eq(assigns(:market_posts).count)
      end

      it 'should respond with market_posts items in any location' do
        subject
        expect(assigns(:market_posts).count).to eq(Content.where(content_category_id: @market_cat.id).
                                               where('pubdate > ?', 30.days.ago).count)
      end
    end

    context 'signed in' do
      before do
        api_authenticate user: @user
      end

      it 'should allow querying by any passed in location_id' do
        get :index, format: :json, location_id: @user.location.id
        expect(assigns(:market_posts).select{|c| c.locations.include? @user.location }.count).to eq(assigns(:market_posts).count)
      end

      it 'should return market_posts items in any location when no location_id passed in' do
        subject
        expect(assigns(:market_posts).count).to eq(Content.where(content_category_id: @market_cat.id).
                                               where('pubdate > ?', 30.days.ago).count)
      end
    end

    describe 'my_town_only restriction logic' do
      before do
        @mp1 = FactoryGirl.create :market_post, my_town_only: true,
          locations: [@user.location]
        @mp2 = FactoryGirl.create :market_post, my_town_only: true,
          locations: [@default_location]
      end

      context 'signed in' do
        before { api_authenticate user: @user }
        it 'should return my_town_only content from the user\'s location' do
          subject
          expect(assigns(:market_posts)).to include(@mp1.content)
        end
        
        it 'should not return my_town_only content other locations' do
          subject
          expect(assigns(:market_posts)).to_not include(@mp2.content)
        end
      end

      context 'not signed in' do
        it 'should not return any my_town_only posts' do
          subject
          expect(assigns(:market_posts)).to_not include([@mp1, @mp2])
        end
      end
    end
  end

  describe 'GET show' do
    before do
      @content = FactoryGirl.create :content, content_category: @market_cat
      # @market_post = FactoryGirl.create :content, content_category: @market_cat, published: true
      @market_post = FactoryGirl.create :market_post, content: @content
    end

    subject { get :show, id: @content.id }

    it 'has 200 status code' do
      subject
      expect(response.code).to eq('200')
    end

    it 'appropriately loads the market_posts object' do
      subject
      expect(assigns(:market_post)).to eq(@content)
    end

    it 'should increment view count' do
      expect{subject}.to change{Content.find(@content.id).view_count}.from(0).to(1)
    end

    describe 'can_edit' do
      before do
        @location = FactoryGirl.create :location, city: 'Another City'
        @user = FactoryGirl.create :user, location: @location
        @market_post.update_attribute(:created_by, @user)
      end

      let(:can_edit) { JSON.parse(response.body)['market_post']['can_edit'] }

      it 'should be true for the content author' do
        api_authenticate user: @user
        subject 
        expect(can_edit).to eq(true)
      end

      it 'should false for a different user' do
        @different_user = FactoryGirl.create :user
        api_authenticate user: @different_user
        subject 
        expect(can_edit).to eq(false)
      end

      it 'should false when a user is not logged in' do
        subject 
        expect(can_edit).to eq(false)
      end
    end

    context 'signed in' do
      before do
        @repo = FactoryGirl.create :repository
        @user = FactoryGirl.create :user
        @consumer_app = FactoryGirl.create :consumer_app, repository: @repo
        @consumer_app.organizations << @market_post.organization
        api_authenticate user: @user, consumer_app: @consumer_app
      end

      it 'should queue record_user_visit' do
        expect{subject}.to have_enqueued_job(BackgroundJob).with('DspService',
                        'record_user_visit', @content, @user, @repo)
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
        expect(assigns(:market_post)).to eq(@content)
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

      it { subject; expect(response.status).to eq 204 }
    end

    describe 'for content that isn\'t market' do
      before { @c = FactoryGirl.create :content }

      it 'should respond with nothing' do
        get :show, id: @c.id
        expect(response.code).to eq '204'
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
        expect(response.code).to eq('204')
      end
    end

    describe 'for market category content' do
      before do
        @content = FactoryGirl.create :content, content_category: @market_cat
      end

      it 'has 200 status code' do
        get :contact, id: @content.id
        expect(response.code).to eq '200'
      end
    end

    describe 'for a market channel content' do
      before do
        post_content = FactoryGirl.create :content, content_category: @market_cat
        @market_post = FactoryGirl.create :market_post, content: post_content
      end

      it 'has 200 status code' do
        get :contact, id: @market_post.content.id
        expect(response.code).to eq '200'
      end
    end
  end

  describe 'PUT update' do
    before do
      @user = FactoryGirl.create :user
      @market_post = FactoryGirl.create :market_post, created_by: @user
      @attrs_for_update = { 
        title: 'This is a changed title',
        price: 'New low price',
        content: 'Hoth'
      }
    end

    subject { put :update, id: @market_post.content.id, market_post: @attrs_for_update }

    context 'not signed in' do
      it 'should respond with 401' do
        subject
        expect(response.code).to eq('401')
      end
    end

    context 'signed in, and allowed to update' do
      # TODO: once we have created_by, add specs to ensure that only the user who 
      # created the object can update it.
      before do
        api_authenticate user: @user
      end

      it 'should update the market post\'s attributes' do
        expect{subject}.to change{@market_post.reload.cost}.to @attrs_for_update[:price]
      end

      it 'should update the associated content\'s attributes' do
        expect{subject}.to change{@market_post.reload.content.title}.to @attrs_for_update[:title]
      end

      it 'should allow clearing out an attribute' do
        @attrs_for_update['contact_phone'] = ''
        subject
        expect(@market_post.reload.contact_phone).to eq ''
      end

      describe 'with invalid parameters' do
        before do
          @attrs_for_update[:title] = ''
        end

        it 'should respond with a 422' do
          subject
          expect(response.code).to eq '422'
        end
      end

      context 'with params organization_id' do
        let(:organization) { FactoryGirl.create(:organization) }
        let(:params_with_org) { @attrs_for_update.merge(organization_id: organization.id) }

        it 'allows the param, but ignores it' do
          put :update, id: @market_post.content.id, market_post: params_with_org
          @market_post.reload
          expect(@market_post.content.organization).to_not eql organization
          expect(response.status).to eql 200
        end
      end

      context 'with consumer_app / repository' do
        before do
          @repo = FactoryGirl.create :repository
          @consumer_app = FactoryGirl.create :consumer_app, repository: @repo
          api_authenticate user: @user, consumer_app: @consumer_app
        end

        it 'should call publish_to_dsp' do
          expect{subject}.to have_enqueued_job(PublishContentJob)
        end
      end

      context 'with extended_reach_enabled true' do
        before do
          @attrs_for_update[:extended_reach_enabled] = true
          @region_location = FactoryGirl.create :location
          stub_const("Location::REGION_LOCATION_ID", @region_location.id)
        end

        it 'should update the market post with locations including REGION_LOCATION_ID' do
          subject
          expect(@market_post.reload.content.location_ids).to include(@region_location.id)
        end
      end

      context 'when marking a post as sold' do

        before do
          @content =  FactoryGirl.create :content
        end
      
        context 'when updating a market post with associated content' do
          it 'updates the market post to sold' do
            put :update, id: @market_post.content.id, market_post: @attrs_for_update.merge(sold: true)
            expect(@market_post.reload.sold).to eq true
          end
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
        expect(response.code).to eq('401')
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
          status: 'selling',
          my_town_only: true
        }
      end

      subject { post :create, market_post: @basic_attrs }

      it 'should respond with 201' do
        subject
        expect(response.code).to eq('201')
      end

      it 'should create a market post' do
        expect{subject}.to change{MarketPost.count}.by(1)
      end

      it 'should create an associated content' do
        expect{subject}.to change{Content.count}.by(1)
        expect(assigns(:market_post).content.present?).to be true
      end

      it 'should correctly set the my_town_only attribute' do
        subject
        expect(assigns(:market_post).content.my_town_only).to be true
      end

      context 'with listserv_id' do
        before do
          @listserv = FactoryGirl.create :vc_listserv
          @basic_attrs[:listserv_id] = @listserv.id
        end

        it 'creates content associated with users home community when enhancing through the listserv' do
          expect{subject}.to change{Content.count}.by(1)
          expect(assigns(:market_post).content.location_ids).to eq([@user.location_id])
        end
      end

      context 'with consumer_app / repository' do
        before do
          @repo = FactoryGirl.create :repository
          @consumer_app = FactoryGirl.create :consumer_app, repository: @repo
          api_authenticate user: @user, consumer_app: @consumer_app
        end

        it 'should queue PublishContentJob' do
          expect{subject}.to have_enqueued_job(PublishContentJob)
        end
      end

      describe 'with invalid parameters' do
        before do
          @basic_attrs.delete :title
        end

        it 'should respond with a 500' do
          subject
          expect(response.code).to eq '500'
        end
      end
    end

  end

end
