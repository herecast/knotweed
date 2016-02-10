require 'spec_helper'

describe Api::V3::BusinessProfilesController do
  describe 'GET index' do
    before do
      @bps = FactoryGirl.create_list :business_profile, 3
    end

    subject { get :index, format: :json }

    it 'has 200 status code' do
      subject
      response.code.should eq '200'
    end

    it 'loads the business profiles' do
      subject
      assigns(:business_profiles).should eq @bps
    end

    describe 'searching' do
      before do
        @search = 'AZSXDCFB123543'
      end

      subject { get :index, format: :json, query: @search }

      it 'should return matches', focus: true do
        sr_content = FactoryGirl.create :content, title: @search
        @search_result = FactoryGirl.create :business_profile, content: sr_content
        index
        subject
        assigns(:business_profiles).should eq [@search_result]
      end
    end
  end

  describe 'GET show' do
    before { @bp = FactoryGirl.create :business_profile }

    subject! { get :show, format: :json, id: @bp.content.id }

    it 'has 200 status code' do
      response.code.should eq '200'
    end

    it 'loads the business profile' do
      assigns(:business_profile).should eq @bp
    end
  end

  describe 'POST create' do
    before do
      @user = FactoryGirl.create :user
      api_authenticate user: @user
      @create_params = {
        name: Faker::Company.name,
        phone: Faker::PhoneNumber.phone_number,
        email: Faker::Internet.email,
        website: Faker::Internet.url,
        address: Faker::Address.street_address,
        city: Faker::Address.city,
        state: Faker::Address.state_abbr,
        zip: Faker::Address.zip,
        type: 'goes_to',
        hours: ['Mo,Tu 13:00-17:00'],
        details: Faker::Hipster.sentence,
        categories: []
      }
    end

    subject { post :create, business_profile: @create_params }

    it { expect{subject}.to change { Content.count }.by 1 }
    it { expect{subject}.to change { BusinessProfile.count }.by 1 }
    it { expect{subject}.to change { Organization.count }.by 1 }
    it { expect{subject}.to change { BusinessLocation.count }.by 1 }

    it 'should associate the new organization with the business profile through content' do
      subject
      BusinessProfile.last.organization.should eq Organization.last
    end

    it 'should associate the new profile with a new business location' do
      subject
      BusinessProfile.last.business_location.should eq BusinessLocation.last
    end
  end

  describe 'PUT update' do
    before do
      @user = FactoryGirl.create :user
      api_authenticate user: @user
      @business_profile = FactoryGirl.create :business_profile
      # test updating at least one attribute in each associated model
      @update_params = {
        name: Faker::Company.name,
        website: Faker::Internet.url,
        phone: Faker::PhoneNumber.phone_number,
        details: Faker::Hipster.sentence,
        type: 'comes_to'
      }
    end

    subject { put :update, business_profile: @update_params, id: @business_profile.content.id }

    it 'should update the associated organization' do
      expect{subject}.to change { @business_profile.organization.reload.website }.to @update_params[:website]
    end

    it 'should update the associated content' do
      expect{subject}.to change { @business_profile.content.reload.raw_content }.to @update_params[:details]
    end

    it 'should update the business_profile' do
      expect{subject}.to change { @business_profile.reload.biz_type }.to @update_params[:type]
    end

    it 'should update the business_location' do
      expect{subject}.to change { @business_profile.business_location.reload.phone }.to @update_params[:phone]
    end
  end
end
