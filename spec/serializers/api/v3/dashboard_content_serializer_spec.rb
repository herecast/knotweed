require 'spec_helper'

describe Api::V3::DashboardContentSerializer do
  before do
    @content = FactoryGirl.create :content
  end

  let (:serialized_object) { JSON.parse(Api::V3::DashboardContentSerializer.new(@content, root: false).to_json) }

  context 'with a parent object' do
    before do
      @market_cat = FactoryGirl.create :content_category, name: 'market'
      @parent = FactoryGirl.create :content, content_category: @market_cat,
        view_count: 25, comment_count: 19
      @content.update_attribute :parent_id, @parent.id
    end

    it 'should include the parent ID' do
      serialized_object['parent_content_id'].should eq(@parent.id)
    end

    it 'should include parent_content_type' do
      serialized_object['parent_content_type'].should eq(@parent.root_content_category.name)
    end

    it 'should use the parent\'s view_count' do
      serialized_object['view_count'].should eq(@parent.view_count)
    end

    it 'should use the parent\'s comment_count' do
      serialized_object['comment_count'].should eq(@parent.comment_count)
    end

    context 'that is an event' do
      before do
        @parent = FactoryGirl.create :event
        @content.update_attribute :parent_id, @parent.content.id
      end
      
      it 'should include parent_event_instance_id' do
        serialized_object['parent_event_instance_id'].should eq(@parent.event_instances.first.id)
      end
    end
  end

  context 'news' do
    it 'should return content_type of "News"' do
      serialized_object['content_type'].should eq('News')
    end
  end

  context 'events' do
    before do
      @event = FactoryGirl.create :event, content: @content
    end

    it 'should include event_instance_id as id' do
      serialized_object['id'].should eq(@event.event_instances.first.id)
    end

    # NOTE: as of now the serializer uses the first event instance id
    # as the ID of the response.
    it 'should include event_id for events' do
      serialized_object['event_id'].should eq(@event.id)
    end
  end

end
