require 'spec_helper'

describe Api::V3::TalkSerializer do
  before do
    @talk_cat = FactoryGirl.create :content_category, name: 'talk_of_the_town'
    @talk = FactoryGirl.create :content, content_category: @talk_cat
  end

  let (:serialized_object) { JSON.parse(Api::V3::TalkSerializer.new(@talk, root: false).to_json) }

  context 'with a parent object' do
    before do
      @market_cat = FactoryGirl.create :content_category, name: 'market'
      @parent = FactoryGirl.create :content, content_category: @market_cat
      @talk.update_attribute :parent_id, @parent.id
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

  end
end
