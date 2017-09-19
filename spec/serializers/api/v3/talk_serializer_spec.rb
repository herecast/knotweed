require 'spec_helper'

describe Api::V3::TalkSerializer do
  before do
    @talk_cat = FactoryGirl.create :content_category, name: 'talk_of_the_town'
    @talk = FactoryGirl.create :content, :located, content_category: @talk_cat
  end

  let (:serialized_object) { JSON.parse(Api::V3::TalkSerializer.new(@talk, root: false).to_json) }

  context 'with a parent object' do
    before do
      @market_cat = FactoryGirl.create :content_category, name: 'market'
      @parent = FactoryGirl.create :content, :located, content_category: @market_cat,
        view_count: 5, commenter_count: 6, comment_count: 7
      @talk.update_attribute :parent_id, @parent.id
    end

    it 'should include the parent ID' do
      expect(serialized_object['parent_content_id']).to eq(@parent.id)
    end

    it 'should include parent_content_type' do
      expect(serialized_object['parent_content_type']).to eq(@parent.root_content_category.name)
    end

    describe 'view_count, comment_count and commenter_count' do
      it 'should be the parent object\'s values' do
        expect(serialized_object['view_count']).to eq(@parent.view_count)
        expect(serialized_object['comment_count']).to eq(@parent.comment_count)
        expect(serialized_object['commenter_count']).to eq(@parent.commenter_count)
      end
    end

    context 'that is an event' do
      before do
        @parent = FactoryGirl.create :event
        @talk.update_attribute :parent_id, @parent.content.id
      end
      
      it 'should include parent_event_instance_id' do
        expect(serialized_object['parent_event_instance_id']).to eq(@parent.event_instances.first.id)
      end

    end

  end
end
