require 'spec_helper'

describe Api::V3::MarketPostsController do
  before do
    @market_cat = FactoryGirl.create :content_category, name: 'market'
  end

  describe 'GET index', sphinx: true do
    before do
      @default_location = FactoryGirl.create :location, city: Location::DEFAULT_LOCATION
      @other_location = FactoryGirl.create :location, city: 'Another City'
      @third_location = FactoryGirl.create :location, city: 'Different Again'
      @user = FactoryGirl.create :user, location: @other_location
      FactoryGirl.create_list :content, 3, content_category: @market_cat, 
        locations: [@default_location], published: true
      FactoryGirl.create_list :content, 5, content_category: @market_cat, 
        locations: [@other_location], published: true
      FactoryGirl.create_list :content, 4, content_category: @market_cat, 
        locations: [@third_location], published: true
      @old_post = FactoryGirl.create :content, content_category: @market_cat,
        locations: [@default_location], published: true, pubdate: 40.days.ago
    end

    subject { get :index, format: :json }

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

    context 'not signed in' do
      it 'should respond with market_posts items' do
        subject
        assigns(:market_posts).select{|c| c.content_category_id == @market_cat.id }.count.should eq(assigns(:market_posts).count)
      end

      it 'should respond with market_posts items in the default location' do
        subject
        assigns(:market_posts).select{|c| c.locations.include? @default_location }.count.should eq(assigns(:market_posts).count)
      end
    end

    context 'signed in' do
      before do
        api_authenticate user: @user
      end

      it 'should not automatically query based on signed in user\'s location' do
        subject
        assigns(:market_posts).select{|c| c.locations.include? @user.location }.count.should eq(0) 
      end

      it 'should allow querying by any passed in location_id' do
        get :index, format: :json, location_id: @user.location.id
        assigns(:market_posts).select{|c| c.locations.include? @user.location }.count.should eq(assigns(:market_posts).count)
      end

      it 'should return market_posts items in the default location when no location_id passed in' do
        subject
        assigns(:market_posts).select{|c| c.locations.include? @default_location }.count.should eq(assigns(:market_posts).count)
      end
    end

  end

  describe 'when user edits the content' do
    before do
      @location = FactoryGirl.create :location, city: 'Another City'
      @user = FactoryGirl.create :user, location: @location
      @market_post = FactoryGirl.create :content, content_category: @market_cat
      @market_post.update_attribute(:created_by, @user)
    end

    subject { get :show, id: @market_post.id, format: :json }

    it 'can_edit should be true for the content author' do
      api_authenticate user: @user
      subject 
      JSON.parse(response.body)["market_post"]["can_edit"].should == true
    end

    it 'can_edit should false for a different user' do
      @location = FactoryGirl.create :location, city: 'Another City'
      @different_user = FactoryGirl.create :user, location: @location
      api_authenticate user: @different_user
      subject 
      JSON.parse(response.body)["market_post"]["can_edit"].should == false
    end

    it 'can_edit should false when a user is not logged in' do
      subject 
      JSON.parse(response.body)["market_post"]["can_edit"].should == false
    end
  end

  describe 'GET show' do
    before do
      @market_post = FactoryGirl.create :content, content_category: @market_cat
    end

    subject { get :show, id: @market_post.id, format: :json }

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
    context 'when requesting app has matching publications' do
      before do
        publication = FactoryGirl.create :publication
        @market_post.publication = publication
        @market_post.save
        @consumer_app = FactoryGirl.create :consumer_app, publications: [publication]
        api_authenticate consumer_app: @consumer_app
      end
      it do
        subject
        response.status.should eq 200
        JSON.parse(response.body)['market_post']['id'].should == @market_post.id
      end
    end
    context 'when requesting app DOES NOT HAVE matching publications' do
      before do
        publication = FactoryGirl.create :publication
        @market_post.publication = publication
        @market_post.save
        @consumer_app = FactoryGirl.create :consumer_app, publications: []
        api_authenticate consumer_app: @consumer_app
      end
      it { subject; response.status.should eq 204 }
    end
  end

  describe 'GET contact' do
    before do
      post_content = FactoryGirl.create :content, content_category: @market_cat
      @market_post = FactoryGirl.create :market_post, content: post_content
    end

    subject { get :contact, id: @market_post.content.id, format: :json }

    it 'has 200 status code' do
      subject
      response.code.should eq('200')
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

      describe 'uploading multiple images' do
        before do
          @file1 = fixture_file_upload('/photo.jpg', 'image/jpg')
          @file2 = fixture_file_upload('/photo2.jpg', 'image/jpg')
          @attrs_for_update[:images] = [{
            image: @file1,
            primary: false
          }, {
            image: @file2,
            primary: true
          }]
        end

        it 'should create Image records for each' do
          expect{subject}.to change{Image.count}.by 2
        end

        it 'should associate the images with the market post\'s content record' do
          expect{subject}.to change{@market_post.content.images.count}.to 2 # from 0 to 2
        end

        it 'should assign the primary attribute appropriately' do
          subject
          expect(@market_post.content.primary_image).to be_present
          expect(@market_post.content.primary_image.image_identifier).to eq(@file2.original_filename)
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
