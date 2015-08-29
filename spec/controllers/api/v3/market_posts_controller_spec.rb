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
      FactoryGirl.create_list :content, 3, content_category: @market_cat, 
        locations: [@default_location], published: true
      FactoryGirl.create_list :content, 5, content_category: @market_cat, 
        locations: [@other_location], published: true
      FactoryGirl.create_list :content, 4, content_category: @market_cat, 
        locations: [@third_location], published: true
    end

    subject { get :index, format: :json }

    it 'has 200 status code' do
      subject
      response.code.should eq('200')
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

      it 'should respond with market_posts items in the user\'s location' do
        subject
        assigns(:market_posts).select{|c| c.locations.include? @user.location }.count.should eq(assigns(:market_posts).count)
      end
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
  end

  describe 'GET contact' do
    before do
      @market_post = FactoryGirl.create :market_post
    end

    subject { get :contact, id: @market_post.content.id, format: :json }

    it 'has 200 status code' do
      subject
      response.code.should eq('200')
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
          locate_address: '300 Main Street Norwich VT 05055'
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
    end

  end

end
