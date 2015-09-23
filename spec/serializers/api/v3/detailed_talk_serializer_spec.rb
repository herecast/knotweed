require 'spec_helper'

describe Api::V3::DetailedTalkSerializer do
  before do
    @talk_cat = FactoryGirl.create :content_category, name: 'talk_of_the_town'
    @talk = FactoryGirl.create :content, content_category: @talk_cat
  end

  let (:serialized_object) { JSON.parse(Api::V3::DetailedTalkSerializer.new(@talk, root: false).to_json) }

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

  end
end
