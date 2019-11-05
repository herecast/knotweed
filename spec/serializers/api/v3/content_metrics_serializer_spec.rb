# frozen_string_literal: true

require 'spec_helper'

describe Api::V3::ContentMetricsSerializer do
  let(:content) { FactoryGirl.create :content }

  let(:context_for_request) { { start_date: Date.yesterday.to_s, end_date: Date.today.to_s } }
  let(:serialized_object) { JSON.parse(Api::V3::ContentMetricsSerializer.new(content, root: false, context: context_for_request).to_json) }

  describe 'comments' do
    let!(:comment) {FactoryGirl.create :comment, content: content }

    it 'should render an array of comments' do
      expect(serialized_object['comments'].length).to eq(1)
      expect(serialized_object['comments'][0]['id']).to eq(comment.id)
    end
  end
end
