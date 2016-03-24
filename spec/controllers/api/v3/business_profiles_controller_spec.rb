require 'spec_helper'

describe Api::V3::BusinessProfilesController do
  describe 'GET index' do
    before do
      @bps = FactoryGirl.create_list :business_profile, 3
      # set all the BP.business_locations to be in the upper valley
      # so they return with the default search options
      @bps.each do |bp|
        bp.business_location.update_attributes(
          latitude: Location::DEFAULT_LOCATION_COORDS[0],
          longitude: Location::DEFAULT_LOCATION_COORDS[1]
        )
      end
      index
    end

    subject { get :index }

    it 'has 200 status code' do
      subject
      response.code.should eq '200'
    end

    it 'loads the business profiles' do
      subject
      assigns(:business_profiles).should eq @bps
    end

    describe "Sorting" do
      let(:mock_results) { double('results', total_entries: 0) }

      it 'sorts by feedback_recommend_avg DESC by default' do
        expect(BusinessProfile).to receive(:search).with(anything, hash_including(order: 'feedback_recommend_avg DESC')).and_return(mock_results)
          get :index, {sort_by: 'score_desc'}
      end

      context 'Given params[:sort_by]=score_desc' do
        it 'tranlates that to highest recommended first' do
          expect(BusinessProfile).to receive(:search).with(anything, hash_including(order: 'feedback_recommend_avg DESC')).and_return(mock_results)
          subject
        end
      end

      context 'Given params[:sort_by]=distance_asc' do
        it 'tranlates that to smallest geodist first' do
          expect(BusinessProfile).to receive(:search).with(anything, hash_including(order: 'geodist ASC')).and_return(mock_results)
          get :index, {sort_by: 'distance_asc'}
        end
      end

      context 'Given params[:sort_by]=rated_desc' do
        it 'tranlates that to most feedback first' do
          expect(BusinessProfile).to receive(:search).with(anything, hash_including(order: 'feedback_count DESC')).and_return(mock_results)
          get :index, {sort_by: 'rated_desc'}
        end
      end

      context 'Given params[:sort_by]=alpha_asc' do
        it 'tranlates that to alphabetical order' do
          expect(BusinessProfile).to receive(:search).with(anything, hash_including(order: 'organization_name ASC')).and_return(mock_results)
          get :index, {sort_by: 'alpha_asc'}
        end
      end

      context 'Given params[:sort_by]=alpha_desc' do
        it 'tranlates that to alphabetical order reversed' do
          expect(BusinessProfile).to receive(:search).with(anything, hash_including(order: 'organization_name DESC')).and_return(mock_results)
          get :index, {sort_by: 'alpha_desc'}
        end
      end
    end

    describe 'searching' do
      before do
        @search = 'AZSXDCFB123543'
        @result = BusinessProfile.first
        @result.content.update_attribute :title, @search
        index
      end

      subject { get :index, query: @search }

      it 'should return matches' do
        subject
        assigns(:business_profiles).should eq [@result]
      end

      describe 'by category_id' do
        before do
          @cat = FactoryGirl.create :business_category
          @bps.first.business_categories << @cat
          index
        end

        it 'should return filtered results' do
          get :index, category_id: @cat.id
          assigns(:business_profiles).should eq [@bps.first]
        end
      end

      describe 'given lat/lng' do
        before do
          # have to set the lat/lngs of the business locations manually
          # as geocoder just uses the same coords for everything in test environments
          BusinessLocation.all.each do |bl|
            bl.update_attributes(
              latitude: Faker::Address.latitude,
              longitude: Faker::Address.longitude
            )
          end
          index
        end

        it 'should return results within radius if specified' do
          bp = BusinessProfile.first
          get :index, lat: bp.business_location.latitude, lng: bp.business_location.longitude,
            radius: 100 # note -- because of a lack of precision in the generated lat/lngs (and because
            # radius is measured in meters) we can't just set this to 0.1 or something. 100 seems to work.
            # It's theoretically possible that this could return another randomly located result, but the odds
            # of that are very very low.
          assigns(:business_profiles).should eq [bp]
        end

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
      @biz_cat = FactoryGirl.create :business_category
      @create_params = {
        name: Faker::Company.name,
        phone: Faker::PhoneNumber.phone_number,
        email: Faker::Internet.email,
        website: Faker::Internet.url,
        address: Faker::Address.street_address,
        city: Faker::Address.city,
        state: Faker::Address.state_abbr,
        zip: Faker::Address.zip,
        has_retail_location: true,
        hours: ['Mo,Tu 13:00-17:00'],
        details: Faker::Hipster.sentence,
        category_ids: [@biz_cat.id]
      }
    end

    subject { post :create, business: @create_params }

    it 'should respond with 201 status code' do
      subject
      response.code.should eq '201'
    end

    it 'should send an email' do
      expect{subject}.to change{ActionMailer::Base.deliveries.count}.by 1
    end

=begin
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

    it 'should associate the new profile with the business category' do
      subject
      BusinessProfile.last.business_categories.should eq [@biz_cat]
    end
=end
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
        has_retail_location: false
      }
    end

    subject { put :update, business: @update_params, id: @business_profile.content.id }

    it 'should update the associated organization' do
      expect{subject}.to change { @business_profile.organization.reload.website }.to @update_params[:website]
    end

    it 'should update the associated content' do
      expect{subject}.to change { @business_profile.content.reload.raw_content }.to @update_params[:details]
    end

    it 'should update the business_profile' do
      expect{subject}.to change { @business_profile.reload.has_retail_location? }.to @update_params[:has_retail_location]
    end

    it 'should update the business_location' do
      expect{subject}.to change { @business_profile.business_location.reload.phone }.to @update_params[:phone]
    end
  end
end
