# frozen_string_literal: true

require 'spec_helper'

describe SearchIndexing::OrganizationSerializer do
  let(:organization) { FactoryGirl.create :organization }
  subject { JSON.parse(SearchIndexing::OrganizationSerializer.new(organization, root: false).to_json) }

  it 'should successfully return a hash' do
    expect(subject['id']).to eq organization.id
  end
end
