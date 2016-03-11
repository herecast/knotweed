require 'spec_helper'

describe Api::V3::BusinessCategorySerializer do
  before do
    @parent = FactoryGirl.create :business_category
    @child = FactoryGirl.create :business_category, parent_ids: [@parent.id]
  end

  describe 'child_ids' do
    it 'should list child IDs' do
      serialized_object = JSON.parse(Api::V3::BusinessCategorySerializer.new(@parent, root: false).to_json)
      serialized_object['child_ids'].should eq [@child.id]
    end
  end

  describe 'parent_ids' do
    it 'should list parent IDs' do
      serialized_object = JSON.parse(Api::V3::BusinessCategorySerializer.new(@child, root: false).to_json)
      serialized_object['parent_ids'].should eq [@parent.id]
    end
  end
end