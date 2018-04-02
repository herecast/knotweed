require 'spec_helper'

describe SearchIndexing::CreatedBySerializer do
  let(:user) { FactoryGirl.create :user }
  subject { JSON.parse(SearchIndexing::CreatedBySerializer.new(user, root: false).to_json) }

  it 'should successfully return a hash' do
    expect(subject['id']).to eq user.id
  end
end
