require 'spec_helper'

describe SearchIndexing::ContentLocationSerializer do
  let(:content_location) { FactoryGirl.create :content_location }
  subject { JSON.parse(SearchIndexing::ContentLocationSerializer.new(content_location, root: false).to_json) }

  it 'should successfully return a hash' do
    expect(subject['id']).to eq content_location.id
  end
end
