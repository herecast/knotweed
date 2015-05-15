require 'spec_helper'

describe Api::V2::CommentsController do

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

      it 'should return the comments associaetd' do
        subject
        assigns(:comments).should eq([@comment.content])
      end

    end

  end

end
