require 'spec_helper'

describe SearchIndexing::LocationSerializer do
  let(:location) { FactoryGirl.create :location }
  subject { JSON.parse(SearchIndexing::LocationSerializer.new(location, root: false).to_json) }

  it 'should successfully return a hash' do
    expect(subject['id']).to eq location.id
  end
end
