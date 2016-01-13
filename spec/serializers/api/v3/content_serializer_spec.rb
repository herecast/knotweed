require 'spec_helper'

describe Api::V3::ContentSerializer do
  before do
    @content = FactoryGirl.create :content
  end

  let (:serialized_object) { JSON.parse(Api::V3::ContentSerializer.new(@content, root: false).to_json) }

  context 'with a parent object' do
    before do
      @market_cat = FactoryGirl.create :content_category, name: 'market'
      @parent = FactoryGirl.create :content, content_category: @market_cat,
        view_count: 5, commenter_count: 6
      @content.update_attribute :parent_id, @parent.id
    end

    it 'should include the parent ID' do
      serialized_object['parent_content_id'].should eq(@parent.id)
    end

    it 'should include parent_content_type' do
      serialized_object['parent_content_type'].should eq(@parent.root_content_category.name)
    end

    describe 'view_count and commenter_count' do
      it 'should be the parent object\'s values' do
        serialized_object['view_count'].should eq(@parent.view_count)
        serialized_object['commenter_count'].should eq(@parent.commenter_count)
      end
    end

    context 'parent is an event' do
      before do
        @parent = FactoryGirl.create :event
        @content.update_attribute :parent_id, @parent.content.id
      end
      
      it 'should include parent_event_instance_id' do
        serialized_object['parent_event_instance_id'].should eq(@parent.event_instances.first.id)
      end

    end

    context 'content is an event with instances in the past' do
      before do
        @event = FactoryGirl.create :event, skip_event_instance: true
        @event_instance =  FactoryGirl.create :event_instance, start_date: 1.month.ago, end_date: 1.week.ago, event: @event
        @content = @event.content
      end

      it 'should include event instance id of first instance' do
        serialized_object['event_instance_id'].should eq @event_instance.id
        serialized_object['starts_at'].should eq @event_instance.start_date.strftime("%Y-%m-%dT%H:%M:%S%:z")
        serialized_object['ends_at'].should eq @event_instance.end_date.strftime("%Y-%m-%dT%H:%M:%S%:z")
      end
    end

    context 'content is an event with instances in the past and future' do
      before do
        @event = FactoryGirl.create :event, skip_event_instance: true
        FactoryGirl.create :event_instance, start_date: 1.month.ago, end_date: 1.week.ago, event: @event
        @next_instance =  FactoryGirl.create :event_instance, start_date: 1.week.from_now, end_date: 1.month.from_now, event: @event
        @content = @event.content
      end

      it 'should include event instance id of next instance' do
        serialized_object['event_instance_id'].should eq @next_instance.id
        serialized_object['starts_at'].should eq @next_instance.start_date.strftime("%Y-%m-%dT%H:%M:%S%:z")
        serialized_object['ends_at'].should eq @next_instance.end_date.strftime("%Y-%m-%dT%H:%M:%S%:z")
      end
    end
  end
end
