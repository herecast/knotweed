# frozen_string_literal: true

require 'spec_helper'

describe SearchIndexing::ContentSerializer do
  let(:content) { FactoryGirl.create :content }
  subject { JSON.parse(SearchIndexing::ContentSerializer.new(content, root: false).to_json) }

  it 'should successfully return a hash' do
    expect(subject['id']).to eq content.id
  end
end
