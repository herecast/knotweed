require 'spec_helper'

describe Api::V3::TalkController do
  before do
    @talk_cat = FactoryGirl.create :content_category, name: 'talk_of_the_town'
    @other_location = FactoryGirl.create :location, city: 'Another City'
    @user = FactoryGirl.create :user, location: @other_location
  end

  describe 'GET index' do
    before do
      @default_location = FactoryGirl.create :location, city: Location::DEFAULT_LOCATION
      @third_location = FactoryGirl.create :location, city: 'Different Again'
      FactoryGirl.create_list :content, 3, content_category: @talk_cat, 
        locations: [@default_location], published: true
      FactoryGirl.create_list :content, 5, content_category: @talk_cat, 
        locations: [@other_location], published: true
      FactoryGirl.create_list :content, 4, content_category: @talk_cat, 
        locations: [@third_location], published: true
      ThinkingSphinx::Test.index 'content_core', 'location_core'
    end

    subject { get :index, format: :json }


    context 'not signed in' do
      it 'should respond with 401 status' do
        subject
        response.code.should eq('401')
      end
    end

    context 'signed in' do
      before do
        api_authenticate user: @user
      end

      it 'has 200 status code' do
        subject
        response.code.should eq('200')
      end

      it 'should respond with talk items in the user\'s location' do
        subject
        assigns(:talk).select{|c| c.locations.include? @user.location }.count.should eq(assigns(:talk).count)
      end
    end

  end

  describe 'GET show' do
    before do
      @talk = FactoryGirl.create :content, content_category: @talk_cat
      ThinkingSphinx::Test.index 'content_core'
      api_authenticate user: @user
    end
    subject { get :show, id: @talk.id, format: :json }
    context do
      it 'has 200 status code' do
        subject
        response.code.should eq('200')
      end

      it 'appropriately loads the talk object' do
        subject
        assigns(:talk).should eq(@talk)
      end

      it 'check view_count' do
        view_count = @talk.view_count
        subject
        talk=JSON.parse(@response.body)
        talk["talk"]["view_count"].should == view_count+1
      end
      it 'check comment_count' do
        comment_count = @talk.comment_count
        subject
        talk=JSON.parse(@response.body)
        talk["talk"]["comment_count"].should == comment_count
      end
      it 'check commenter_count' do
        commenter_count = @talk.commenter_count
        subject
        talk=JSON.parse(@response.body)
        talk["talk"]["commenter_count"].should == commenter_count
      end

      it 'should increment view count' do
        expect{subject}.to change{Content.find(@talk.id).view_count}.from(0).to(1)
      end
    end
    context 'when user has an avatar' do
      before do
        google_logo_stub
        @user.remote_avatar_url='https://www.google.com/images/srpr/logo11w.png'
        @user.save
        @talk.created_by = @user
        @talk.save
      end
      
      it 'serializer should return author_image_url' do
        subject
        JSON.parse(response.body)['talk']['author_image_url'].should == @user.avatar.url
      end
    end
  end

  describe 'PUT update' do
    before do
      @talk = FactoryGirl.create :comment
    end

    context 'not signed in' do
      it 'should respond with 401' do
        put :update, id: @talk.content.id
        response.code.should eq('401')
      end
    end

    context 'signed in' do
      before do
        api_authenticate user: @user
        @file = fixture_file_upload('/photo.jpg', 'image/jpg')
      end

      subject { put :update, id: @talk.content.id, talk: { image: @file } }

      it 'should respond with 200' do
        subject
        response.code.should eq('200')
      end

      it 'should create a new Image' do
        expect{subject}.to change{Image.count}.by(1)
      end

      it 'should associate a new Image with the Content record' do
        subject
        (assigns(:content).reload.images.present?).should eq(true)
      end

    end

  end

  describe 'POST create' do
    before do
      @basic_attrs = {
        title: 'Some Title Here',
        content: 'Hello this is the body'
      }
    end

    subject { post :create, talk: @basic_attrs }

    context 'not signed in' do
      it 'should respond with 401' do
        subject
        response.code.should eq('401')
      end
    end

    context 'signed in' do
      before do
        api_authenticate user: @user
      end

      it 'should respond with 201' do
        subject
        response.code.should eq('201')
      end

      it 'should create a comment' do
        expect{subject}.to change{Comment.count}.by(1)
      end

      it 'should create an associated content object' do
        expect{subject}.to change{Content.count}.by(1)
        (assigns(:talk).content.present?).should be true
      end
    end
  end

end
