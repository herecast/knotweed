require 'spec_helper'
require 'json'

describe Api::V3::CommentsController do

  describe 'GET index' do
    it 'should fail without content_id' do
      expect { get :index, format: :json}.to raise_error
    end

    describe 'given content_id' do
      before do
        user = FactoryGirl.create :user
        @content = FactoryGirl.create :content
        @comment = FactoryGirl.create :comment 
        @comment.content.update_attribute :parent_id, @content.id 
        @comment.content.update_attribute :created_by, user
      end

      subject { get :index, format: :json, content_id: @content.id }

      it 'should return the coments associated' do
        subject
        assigns(:comments).should eq([@comment.content])
      end
    end
    
    describe 'nested comments' do
      before do
        @event = FactoryGirl.create :event
        @comment1 = FactoryGirl.create :comment
        @comment1.content.update_attributes(parent_id: @event.content.id,
                                            pubdate: 2.hours.ago)
        @comment1.content.update_attribute :created_by, FactoryGirl.create(:user)
        @comment2 = FactoryGirl.create :comment
        @comment2.content.update_attributes(parent_id: @comment1.content.id,
                                            pubdate: 1.hour.ago)
        @comment2.content.update_attribute :created_by, FactoryGirl.create(:user)
        @comment3 = FactoryGirl.create :comment
        @comment3.content.update_attributes(parent_id: @comment1.content.id,
                                            pubdate: Time.now)
        @comment3.content.update_attribute :created_by, FactoryGirl.create(:user)
      end
    
      subject! { get :index, format: :json, content_id: @event.content.id }

      it 'should return the results flattened and ordered' do
        # pubdate time varies based on when the Factory creates them, so need to order first
        # to match what the controller does
        comments = [@comment3, @comment2, @comment1].map{ |c| comment_format(c) }
        expected = {comments: comments}.stringify_keys
        JSON.parse(response.body).should eq(expected)
      end
    end
    
    describe 'ordered by pubdate DESC' do
      before do
        @event = FactoryGirl.create :event
        @comment1 = FactoryGirl.create :comment, pubdate: Time.parse('2014-01-01')  
        @comment1.content.update_attribute :created_by, FactoryGirl.create(:user)
        @comment1.content.update_attribute :parent, @event.content
        @comment2 = FactoryGirl.create :comment, pubdate: Time.parse('2014-02-01')
        @comment2.content.update_attribute :created_by, FactoryGirl.create(:user)
        @comment2.content.update_attribute :parent, @comment1.content
        @comment3 = FactoryGirl.create :comment, pubdate: Time.parse('2014-03-01')
        @comment3.content.update_attribute :parent, @comment2.content
        @comment3.content.update_attribute :created_by, FactoryGirl.create(:user)
      end

      subject! { get :index, format: :json, content_id: @event.content.id }

      it 'should return ordered results' do
        expected = {comments: [comment_format(@comment3), comment_format(@comment2), comment_format(@comment1)]}.stringify_keys
        JSON.parse(response.body).should eq(expected)
      end
    end

    describe 'when avatar is present' do
      before do
        google_logo_stub
        user = FactoryGirl.create :user, remote_avatar_url:  "https://www.google.com/images/srpr/logo11w.png"
        @content = FactoryGirl.create :content
        @comment = FactoryGirl.create :comment 
        @comment.content.update_attribute :parent_id, @content.id 
        @comment.content.update_attribute :created_by, user
      end

      subject! { get :index, format: :json, content_id: @content.id }

      it 'should include avatar url in the response' do
        JSON.parse(response.body).should eq({comments: [comment_format(@comment)]}.stringify_keys)
      end
    end

  end

  describe 'POST create' do
    before do
      @event = FactoryGirl.create :event
      @user = FactoryGirl.create :user
      api_authenticate user: @user
    end

    subject { post :create, comment: { content: 'fake', parent_content_id: @event.content.id } }

    context 'should not allow creation if user unauthorized' do
      before { api_authenticate success: false }
      it do
        subject
        response.code.should eq('401')
        Comment.count.should eq(0)
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

    it 'should automatically set organization to DailyUV' do
      subject
      response.code.should eq('201')
      assigns(:comment).content.parent.should eq(@event.content)
      assigns(:comment).organization.name.should eq('DailyUV')
    end
  end

  private

  def comment_format(comment)
    # r means results
    r = {}
    r[:id] = comment.channel.id
    r[:content] = comment.sanitized_content
    r[:user_id] = comment.created_by.id
    r[:user_name] = comment.created_by.name
    r[:user_image_url] = comment.created_by.try(:avatar).try(:url)
    r[:pubdate] = comment.pubdate.strftime("%Y-%m-%dT%H:%M:%S%:z")
    r[:parent_content_id] = comment.parent_id
    r[:content_id] = comment.content.id
    r.stringify_keys
  end

end
