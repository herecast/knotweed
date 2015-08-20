require 'spec_helper'

describe Api::V3::ListservsController do

  describe 'GET index' do
    before do
      FactoryGirl.create_list :listserv, 3
    end

    subject { get :index, format: :json }

    it 'has a 200 status code' do
      subject
      response.code.should eq('200')
    end

    it 'assigns all listservs to instance variable' do
      subject
      assigns(:listservs).count.should eq(Listserv.count)
    end

  end

end
