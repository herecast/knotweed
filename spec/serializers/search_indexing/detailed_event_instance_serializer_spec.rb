require 'spec_helper'

describe SearchIndexing::DetailedEventInstanceSerializer do
  let(:event_instance) { FactoryGirl.create :event_instance }
  subject { JSON.parse(SearchIndexing::DetailedEventInstanceSerializer.new(event_instance, root: false).to_json) }

  it 'should successfully return a hash' do
    expect(subject['id']).to eq event_instance.id
  end
end
