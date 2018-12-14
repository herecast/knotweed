require 'spec_helper'

describe Api::V3::ListservsController, :type => :controller do
  describe 'GET index' do
    before do
      FactoryGirl.create :listserv
      FactoryGirl.create :listserv, list_type: 'internal_digest'
      FactoryGirl.create :listserv, list_type: 'external_list'
    end

    subject { get :index, format: :json }

    it 'has a 200 status code' do
      subject
      expect(response.code).to eq('200')
    end

    it 'only returns listservs that are sending digests and are not a custom digest' do
      subject
      expect(assigns(:listservs).count).to eq 2
    end
  end
end
