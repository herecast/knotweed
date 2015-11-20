require 'spec_helper'

describe Api::V3::ContentMetricsSerializer do
  before do
    @content = FactoryGirl.create :content
  end

  let (:serialized_object) { JSON.parse(Api::V3::ContentMetricsSerializer.new(@content, root: false).to_json) }

  describe 'comments' do
    before do
      @comment1 = FactoryGirl.create :comment
      @comment1.content.update_attribute :parent_id, @content.id
    end

    it 'should render an array of comments' do
      serialized_object['comments'].length.should eq(1)
      serialized_object['comments'][0]['id'].should eq(@comment1.id)
    end
  end

end
