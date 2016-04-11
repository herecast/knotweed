require 'spec_helper'

describe LocationsController, type: :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  describe 'GET #edit' do
    before do
      @location = FactoryGirl.create :location
    end

    subject { get :edit, id: @location.id, format: 'js' }

    it "should respond with 200 status code" do
      subject
      expect(response.code).to eq '200'
    end
  end

  describe 'GET #new' do

    subject { get :new, format: 'js' }

    it "should respond with 200 status code" do
      subject
      expect(response.code).to eq '200'
    end
  end

  describe 'POST #create' do

    subject { post :create, location: { zip: '03770' }, format: 'js' }

    it "should create location" do
      expect{ subject }.to change{ Location.count }.by 1
      expect(response.code).to eq '200'
    end
  end

end