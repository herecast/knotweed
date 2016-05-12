require 'spec_helper'

describe Api::V3::DashboardContentSerializer do
  before do
    @content = FactoryGirl.create :content
  end

  let (:serialized_object) { JSON.parse(Api::V3::DashboardContentSerializer.new(@content, root: false).to_json) }

  [:id,
   :title,
   :parent_content_id,
   :content_type,
   :comment_count,
   :view_count,
   :published_at,
   :event_id,
   :parent_content_type,
   :parent_event_instance_id,
   :content_id,
   :has_metrics_reports,
   :updated_at
  ].each do |field|

    it "returns field: #{field.to_s}" do
      expect(serialized_object).to have_key field.to_s
    end

  end

  context 'with a parent object' do
    before do
      @market_cat = FactoryGirl.create :content_category, name: 'market'
      @parent = FactoryGirl.create :content, content_category: @market_cat,
        view_count: 25, comment_count: 19
      @content.update_attribute :parent_id, @parent.id
    end

    it 'should include the parent ID' do
      expect(serialized_object['parent_content_id']).to eq(@parent.id)
    end

    it 'should include parent_content_type' do
      expect(serialized_object['parent_content_type']).to eq(@parent.root_content_category.name)
    end

    it 'should use the parent\'s view_count' do
      expect(serialized_object['view_count']).to eq(@parent.view_count)
    end

    it 'should use the parent\'s comment_count' do
      expect(serialized_object['comment_count']).to eq(@parent.comment_count)
    end

    context 'that is an event' do
      before do
        @parent = FactoryGirl.create :event
        @content.update_attribute :parent_id, @parent.content.id
      end
      
      it 'should include parent_event_instance_id' do
        expect(serialized_object['parent_event_instance_id']).to eq(@parent.event_instances.first.id)
      end
    end
  end

  context 'news' do
    it 'should return content_type of "News"' do
      expect(serialized_object['content_type']).to eq('News')
    end
  end

  context 'events' do
    before do
      @event = FactoryGirl.create :event, content: @content
    end

    it 'should include event_instance_id as id' do
      expect(serialized_object['id']).to eq(@event.event_instances.first.id)
    end

    # NOTE: as of now the serializer uses the first event instance id
    # as the ID of the response.
    it 'should include event_id for events' do
      expect(serialized_object['event_id']).to eq(@event.id)
    end
  end

end
