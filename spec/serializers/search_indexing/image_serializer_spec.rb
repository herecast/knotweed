require 'spec_helper'

describe SearchIndexing::ImageSerializer do
  let(:image) { FactoryGirl.create :image }
  subject { JSON.parse(SearchIndexing::ImageSerializer.new(image, root: false).to_json) }

  it 'should successfully return a hash' do
    expect(subject['id']).to eq image.id
  end
end
