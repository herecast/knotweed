require 'spec_helper'

describe Api::V3::ListservsController, :type => :controller do

  describe 'GET index' do
    before do
      FactoryGirl.create_list :listserv, 2
      FactoryGirl.create :listserv, reverse_publish_email: 'mail@example.org'
    end

    subject { get :index, format: :json }

    it 'has a 200 status code' do
      subject
      expect(response.code).to eq('200')
    end

    it 'only returns listservs that are sending digests and displaying subscriptions' do
      subject
      expect(assigns(:listservs).count).to eq 1
    end

  end

end
