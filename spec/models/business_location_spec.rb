# == Schema Information
#
# Table name: business_locations
#
#  id                  :bigint(8)        not null, primary key
#  name                :string(255)
#  address             :string(255)
#  phone               :string(255)
#  email               :string(255)
#  hours               :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  organization_id     :bigint(8)
#  latitude            :float
#  longitude           :float
#  venue_url           :string(255)
#  locate_include_name :boolean          default(FALSE)
#  city                :string(255)
#  state               :string(255)
#  zip                 :string(255)
#  status              :string(255)
#  created_by_id       :integer
#  updated_by_id       :integer
#  service_radius      :decimal(10, )
#
# Indexes
#
#  idx_16441_index_business_locations_on_city        (city)
#  idx_16441_index_business_locations_on_created_by  (created_by)
#  idx_16441_index_business_locations_on_name        (name)
#

require 'spec_helper'

describe BusinessLocation, :type => :model do
  include_examples 'Auditable', BusinessLocation

  before do
	  @business_location = FactoryGirl.create :business_location
  end

  describe "validation" do
    context "when state is present" do
      it "must be two-letters long" do
        business_location = FactoryGirl.build :business_location, state: '123'
        expect(business_location).not_to be_valid
      end
    end
  end

  describe "#select_option_label" do
    it "returns formatted address" do
      label = @business_location.select_option_label
      expect(label).to include(@business_location.name, @business_location.address, @business_location.address, @business_location.city, @business_location.state, @business_location.zip)
    end
  end

  describe "#geocoding_address" do
    context "when the business has a name" do
      it "returns address with name" do
        @business_location.update_attribute(:locate_include_name, true)
        expect(@business_location.geocoding_address).to include(@business_location.name)
      end
    end
  end

  describe '#location' do
    context 'when location exists with matching city and state' do
      let!(:location) do
        FactoryGirl.create :location
      end

      let!(:business_location) do
        FactoryGirl.create :business_location,
          city: location.city,
          state: location.state
      end

      subject { business_location.location }

      it 'returns the location record' do
        expect(subject).to eql location
      end

      context 'case insensitive' do
        before do
          business_location.update city: location.city.upcase, state: location.state.downcase
        end

        it do
          expect(subject).to eql location
        end
      end
    end

    context 'no matching city/state location' do
      describe 'finds nearest location' do
        let(:business_location) do
          FactoryGirl.create :business_location, coordinates: [0, 0]
        end

        let!(:nearest) do
          FactoryGirl.create :location,
            city: 'nearborough',
            coordinates: Geocoder::Calculations.random_point_near(
              business_location.coordinates, 5, units: :mi
            )
        end

        let!(:other) do
          FactoryGirl.create :location,
            coordinates: Geocoder::Calculations.endpoint(
              business_location.coordinates,
              90,
              7, units: :mi
            )
        end

        subject { business_location.location }

        it do
          expect(subject).to eql nearest
        end

        describe 'nearest location has parent which is not a region' do
          let!(:parent) {
            FactoryGirl.create :location,
              city: 'parent town',
              is_region: false,
              consumer_active: true
          }

          before do
            nearest.parents << parent
            nearest.save!
          end

          it 'returns the parent' do
            expect(subject).to eql parent
          end
        end
      end

      describe 'nearest location outside of 10 miles' do
        let(:business_location) do
          FactoryGirl.create :business_location, coordinates: [0, 0]
        end

        let!(:nearest) do
          degrees = 90
          distance = 11
          FactoryGirl.create :location,
            coordinates: Geocoder::Calculations.endpoint(
              business_location.coordinates,
              degrees,
              distance,
              units: :mi
            )
        end

        subject { business_location.location }

        it 'returns nil' do
          expect(subject).to be nil
        end
      end
    end
  end
end
