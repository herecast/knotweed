require 'spec_helper'

describe Api::V3::CommentsController do

  describe 'GET index' do
    it 'should respond with 200 code' do
      get :index, format: :json
      response.code.should eq('200')
    end

    describe 'given event_instance_id' do
      before do
        @event_instance = FactoryGirl.create(:event).event_instances.first
        @comment = FactoryGirl.create(:comment)
        @comment.content.update_attribute :parent_id, @event_instance.event.content.id
      end

      subject { get :index, format: :json, event_instance_id: @event_instance.id }

      it 'should return the comments associated' do
        subject
        assigns(:comments).should eq([@comment.content])
      end

    end

  end

  describe 'POST create' do
    before do
      @event = FactoryGirl.create :event
      @user = FactoryGirl.create :user
      
      request.env['HTTP_AUTHORIZATION'] = "Token token=#{@user.authentication_token}, email=#{@user.email}"
    end

    context 'should not allow creation without current user specified' do
      before { request.env['HTTP_AUTHORIZATION'] =  '' }
      it do
        post :create, format: :json, comment: { content: 'fake', parent_id: @event.content.id }
        response.code.should eq('401')
        Comment.count.should eq(0)
      end
    end

    it 'should create a comment given a parent_id' do
      post :create, format: :json, 
        comment: { content: 'fake', parent_id: @event.content.id }
      response.code.should eq('201')
      assigns(:comment).content.parent.should eq(@event.content)
    end

    it 'should automatically set publication to DailyUV' do
      post :create, format: :json, 
        comment: { content: 'fake', parent_id: @event.content.id }
      response.code.should eq('201')
      assigns(:comment).content.parent.should eq(@event.content)
      assigns(:comment).publication.name.should eq('DailyUV')
    end

    it 'should not create a comment given an event_instance_id' do
      expect { 
        post :create, format: :json, 
        comment: { content: 'fake', \
          event_instance_id: @event.event_instances.first.id } 
      }.to raise_error
    end
  end

end
