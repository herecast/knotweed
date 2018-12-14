require 'spec_helper'

describe SearchIndexing::VenueSerializer do
  let(:business_location) { FactoryGirl.create :business_location }
  subject { JSON.parse(SearchIndexing::VenueSerializer.new(business_location, root: false).to_json) }

  it 'should successfully return a hash' do
    expect(subject['id']).to eq business_location.id
  end
end
