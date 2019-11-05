# frozen_string_literal: true

require 'spec_helper'

describe Api::V3::CommentSerializer do
  let(:comment) { FactoryGirl.create :comment }
  subject { JSON.parse(Api::V3::CommentSerializer.new(comment, root: false).to_json) }

  it 'should successfully return a hash' do
    expect(subject['id']).to eq comment.id
  end
end
