require 'spec_helper'

describe Api::V3::ListservsController, :type => :controller do

  describe 'GET index' do
    before do
      FactoryGirl.create_list :listserv, 3
    end

    subject { get :index, format: :json }

    it 'has a 200 status code' do
      subject
      expect(response.code).to eq('200')
    end

    it 'assigns all listservs to instance variable' do
      subject
      expect(assigns(:listservs).count).to eq(Listserv.count)
    end

  end

end
