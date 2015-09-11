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
        @comment1.content.update_attribute :parent, @event.content
        @comment1.content.update_attribute :created_by, FactoryGirl.create(:user)
        @comment2 = FactoryGirl.create :comment
        @comment2.content.update_attribute :parent, @comment1.content
        @comment2.content.update_attribute :created_by, FactoryGirl.create(:user)
        @comment3 = FactoryGirl.create :comment
        @comment3.content.update_attribute :parent, @comment2.content
        @comment3.content.update_attribute :created_by, FactoryGirl.create(:user)
      end
    
      subject! { get :index, format: :json, content_id: @event.content.id }

      it 'should return the results flattened' do
        expected = {comments: [comment_format(@comment1), comment_format(@comment2), comment_format(@comment3)]}.stringify_keys
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

  end

  describe 'POST create' do
    before do
      @event = FactoryGirl.create :event
      @user = FactoryGirl.create :user
      api_authenticate user: @user
    end

    context 'should not allow creation if user unauthorized' do
      before { api_authenticate success: false }
      it do
        post :create, format: :json, comment: { content: 'fake', parent_content_id: @event.content.id }
        response.code.should eq('401')
        Comment.count.should eq(0)
      end
    end

    it 'should create a comment given a parent_content_id' do
      post :create, format: :json, 
        comment: { content: 'fake', parent_content_id: @event.content.id }
      response.code.should eq('201')
      assigns(:comment).content.parent.should eq(@event.content)
    end

    it 'should automatically set publication to DailyUV' do
      post :create, format: :json, 
        comment: { content: 'fake', parent_content_id: @event.content.id }
      response.code.should eq('201')
      assigns(:comment).content.parent.should eq(@event.content)
      assigns(:comment).publication.name.should eq('DailyUV')
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
    #r[:user_image_url]
    r[:pubdate] = comment.pubdate.strftime("%Y-%m-%dT%H:%M:%S%:z")
    r[:parent_content_id] = comment.parent_id
    r[:content_id] = comment.content.id
    r.stringify_keys
  end

end
