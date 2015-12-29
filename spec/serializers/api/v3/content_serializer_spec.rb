require 'spec_helper'

describe Api::V3::ContentSerializer do
  before do
    @content = FactoryGirl.create :content
  end

  let (:serialized_object) { JSON.parse(Api::V3::ContentSerializer.new(@content, root: false).to_json) }

  it 'should set pubdate' do
    serialized_object['published_at'].should eq @content.pubdate.strftime("%Y-%m-%dT%H:%M:%S%:z")
  end

  context 'with a parent object' do
    before do
      @market_cat = FactoryGirl.create :content_category, name: 'market'
      @parent = FactoryGirl.create :content, content_category: @market_cat
      @content.update_attribute :parent_id, @parent.id
    end

    it 'should include the parent ID' do
      serialized_object['parent_content_id'].should eq(@parent.id)
    end

    it 'should include parent_content_type' do
      serialized_object['parent_content_type'].should eq(@parent.root_content_category.name)
    end

    describe 'view_count and commenter_count' do
      before do
        # stub out these numbers to check they're returned
        @parent.view_count = 5
        @parent.commenter_count = 6
        @parent.save
      end

      it 'should be the parent object\'s values' do
        serialized_object['view_count'].should eq(@parent.view_count)
        serialized_object['commenter_count'].should eq(@parent.commenter_count)
      end
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

  context 'when content is an event with a future event_instance' do
    before do
      @event = FactoryGirl.create :event, content: @content, skip_event_instance: true
      @event_instance =  FactoryGirl.create :event_instance, event: @event, start_date: 1.week.from_now
    end

    it 'should have the start_date of the next_instance as pudate' do
      serialized_object['published_at'].should eq @event_instance.start_date.strftime("%Y-%m-%dT%H:%M:%S%:z")
    end
  end

end
