require 'spec_helper'

describe Api::V3::BusinessProfilesController, :type => :controller do
  describe 'GET index', elasticsearch: true do
    before do
      bls = FactoryGirl.create_list :business_location, 3
      # set all the BP.business_locations to be in the upper valley
      # so they return with the default search options
      bls.each do |bl|
        bl.update_attributes(
          latitude: Location::DEFAULT_LOCATION_COORDS[0],
          longitude: Location::DEFAULT_LOCATION_COORDS[1]
        )
        FactoryGirl.create :business_profile, business_location: bl
      end
      @bps = BusinessProfile.all
    end

    subject { get :index }

    it 'has 200 status code' do
      subject
      expect(response.code).to eq '200'
    end

    it 'loads the business profiles' do
      subject
      expect(assigns(:business_profiles)).to match_array(@bps)
    end

    describe 'excludes archived businesses' do
      before do
        @archived = FactoryGirl.create :business_profile, archived: true
        @archived.business_location.update_attributes(
          latitude: Location::DEFAULT_LOCATION_COORDS[0],
          longitude: Location::DEFAULT_LOCATION_COORDS[1]
        )
      end

      it do
        subject
        expect(assigns(:business_profiles)).to_not include @archived
      end
    end

    describe 'excludes businesses with existence 0<existence<0.4' do
      before do
        @nonexistent = FactoryGirl.create :business_profile, existence: 0.3
        @nonexistent.business_location.update_attributes(
          latitude: Location::DEFAULT_LOCATION_COORDS[0],
          longitude: Location::DEFAULT_LOCATION_COORDS[1]
        )
      end

      it do
        subject
        expect(assigns(:business_profiles)).to_not include @nonexistent
      end
    end

    describe "Sorting" do
      let(:mock_results) { double('results', total_entries: 0) }

      let(:best_score_order) do
        [
          { feedback_recommend_avg: :desc },
          { feedback_count: :desc },
          geodist_clause,
          { business_location_name: :asc }
        ]
      end
      
      let(:geodist_clause) do
        { 
          _geo_distance: {
            'location' => Location::DEFAULT_LOCATION_COORDS.join(','),
            'order' => 'asc',
            'unit' => 'mi'
          }
        }
      end
      let(:closest_order) do
        [
          geodist_clause,
          { feedback_recommend_avg: :desc },
          { feedback_count: :desc },
          { business_location_name: :asc }
        ]
      end

      let(:most_rated_order) do
        [
          { feedback_count: :desc },
          { feedback_recommend_avg: :desc },
          geodist_clause,
          { business_location_name: :asc }
        ]
      end

      let(:alpha_order) do
        [
          { business_location_name: :asc },
          { feedback_recommend_avg: :desc },
          { feedback_count: :desc },
          geodist_clause
        ]
      end

      it 'sorts by feedback_recommend_avg DESC by default' do
        expect(BusinessProfile).to receive(:search).with(anything, hash_including(order: best_score_order)).and_return(mock_results)
        get :index
      end

      context 'Given params[:sort_by]=score_desc' do
        it 'tranlates that to highest recommended first' do
          expect(BusinessProfile).to receive(:search).with(anything, hash_including(order: best_score_order)).and_return(mock_results)
          get :index, { sort_by: 'score_desc' }
        end
      end

      context 'Given params[:sort_by]=distance_asc' do
        it 'tranlates that to smallest geodist first' do
          expect(BusinessProfile).to receive(:search).with(anything, hash_including(order: closest_order)).and_return(mock_results)
          get :index, {sort_by: 'distance_asc'}
        end
      end

      context 'Given params[:sort_by]=rated_desc' do
        it 'tranlates that to most feedback first' do
          expect(BusinessProfile).to receive(:search).with(anything, hash_including(order: most_rated_order)).and_return(mock_results)
          get :index, {sort_by: 'rated_desc'}
        end
      end

      context 'Given params[:sort_by]=alpha_asc' do
        it 'tranlates that to alphabetical order' do
          expect(BusinessProfile).to receive(:search).with(anything, hash_including(order: alpha_order)).and_return(mock_results)
          get :index, {sort_by: 'alpha_asc'}
        end
      end

      context 'Given params[:sort_by]=alpha_desc' do
        it 'tranlates that to alphabetical order reversed' do
          expect(BusinessProfile).to receive(:search).with(anything, hash_including(order: [{ business_location_name: :desc }])).and_return(mock_results)
          get :index, {sort_by: 'alpha_desc'}
        end
      end
    end

    describe 'searching' do
      before do
        @search = 'AZSXDCFB123543'
        @result = BusinessProfile.first
        @result.business_location.update_attribute :name, @search
        @result.reindex
        BusinessProfile.searchkick_index.refresh
      end

      subject { get :index, query: @search }

      it 'should return matches' do
        subject
        expect(assigns(:business_profiles)).to match_array [@result]
      end

      describe 'by category_id' do
        before do
          @cat = FactoryGirl.create :business_category
          @cat2 = FactoryGirl.create :business_category, parents: [@cat]
          @bps.first.business_categories << @cat
          @bps.last.business_categories << @cat2
        end

        it 'should return filtered results' do
          get :index, category_id: @cat2.id
          expect(assigns(:business_profiles)).to match_array [@bps.last]
        end

        it 'should return results for categories and their children' do
          get :index, category_id: @cat
          expect(assigns(:business_profiles)).to match_array [@bps.first, @bps.last]
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
          BusinessProfile.reindex
          BusinessProfile.searchkick_index.refresh
        end

        it 'should return results within radius if specified' do
          bp = BusinessProfile.first
          get :index, lat: bp.business_location.latitude, lng: bp.business_location.longitude,
            radius: 1
          expect(assigns(:business_profiles)).to match_array [bp]
        end

      end

    end
  end

  describe 'GET show' do
    before { @bp = FactoryGirl.create :business_profile }

    subject! { get :show, format: :json, id: @bp.id }

    it 'has 200 status code' do
      expect(response.code).to eq '200'
    end

    it 'loads the business profile' do
      expect(assigns(:business_profile)).to eq @bp
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
      expect(response.code).to eq '201'
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
      # test updating at least one attribute in each associated model
      @update_params = {
        name: Faker::Company.name,
        website: Faker::Internet.url,
        phone: Faker::PhoneNumber.phone_number,
        details: Faker::Hipster.sentence,
        has_retail_location: false
      }
    end

    subject { put :update, business: @update_params, id: @business_profile.id }

    context 'for a claimed business' do
      before do
        @business_profile = FactoryGirl.create :business_profile, :claimed
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

    context 'for an unclaimed business' do
      before do
        @business_profile = FactoryGirl.create :business_profile
      end

      it 'should respond with 422' do
        subject
        expect(response.code).to eq '422'
      end
    end
  end
end
