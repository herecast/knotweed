require 'spec_helper'

describe Api::V3::BusinessCategorySerializer do
  before do
    @business_category = FactoryGirl.create :business_category
    @child = FactoryGirl.create :business_category, parent: @business_category
  end

  let (:serialized_object) { JSON.parse(Api::V3::BusinessCategorySerializer.new(@business_category, root: false).to_json) }

  describe 'children' do
    it 'should serialize child records' do
      serialized_object['children'].length.should eq 1
      serialized_object['children'][0].should eq JSON.parse(Api::V3::BusinessCategorySerializer.new(@child, root: false).to_json)
    end
  end

end
