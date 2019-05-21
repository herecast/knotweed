# frozen_string_literal: true

require 'rails_helper'

def serialized_location(location)
  {
    location: {
      id: location.id,
      city: location.city,
      state: location.state,
      latitude: an_instance_of(Float),
      longitude: an_instance_of(Float),
      image_url: location.image_url
    }
  }
end

RSpec.describe 'Locations API Endpoints', type: :request do
  describe 'GET /api/v3/locations' do
    context 'When locations exist' do
      let!(:locations) { FactoryGirl.create_list :location, 3, consumer_active: true }

      it 'returns expected json list of locations' do
        get '/api/v3/locations'

        expect(response_json[:locations].length).to eq 3

        location = locations.first
        serialized = serialized_location(location)[:location]

        expect(response_json[:locations].find { |l| l[:id].eql? location.id }).to match serialized
      end
    end

    describe '?near= parameter' do
      let(:location) { FactoryGirl.create :location, coordinates: [0, 0] }
      let(:parameters) do
        {
          near: location.slug
        }
      end

      subject { get '/api/v3/locations', params: parameters }

      context 'no radius given' do
        it 'responds with a 422' do
          subject
          expect(response.code).to eql '422'
        end
      end

      context 'given a radius' do
        let(:radius) { 20 }

        before do
          parameters[:radius] = radius
        end

        let!(:locations_within_radius) do
          3.times.collect do
            FactoryGirl.create :location, coordinates: Geocoder::Calculations.random_point_near(
              location, radius, units: :mi
            )
          end
        end

        let!(:locations_outside_radius) do
          FactoryGirl.create_list :location, 3, coordinates: [40, 40]
        end

        it 'responds with a 200' do
          subject
          expect(response.code).to eql '200'
        end

        it 'returns the locations within the radius of specified location id' do
          subject
          location_ids = response_json[:locations].map { |l| l[:id] }
          expect(location_ids).to include *locations_within_radius.map(&:id)
          expect(location_ids).to_not include *locations_outside_radius.map(&:id)
        end
      end
    end
  end

  describe 'GET /api/v3/location/:id' do
    let(:location) { FactoryGirl.create :location }

    context 'given an id' do
      subject { get '/api/v3/locations/' + location.id.to_s }

      it 'returns the location json' do
        subject
        expect(response_json).to match serialized_location(location)
      end
    end

    context 'given a slug' do
      subject { get '/api/v3/locations/' + location.slug }

      it 'returns the location json' do
        subject
        expect(response_json).to match serialized_location(location)
      end
    end

    context 'location id is not a valid location' do
      subject { get '/api/v3/locations/' + '123-not-valid' }

      it 'responds with 404 status code' do
        subject
        expect(response_json).to match({}) # empty hash payload
        expect(response.code).to eql '404'
      end
    end
  end

  describe 'GET /api/v3/locations/locate' do
    let!(:other_locations) { FactoryGirl.create_list :location, 3 }
    let(:location) { FactoryGirl.create :location }

    context 'with coords passed' do
      let(:lat) { Faker::Address.latitude }
      let(:lng) { Faker::Address.longitude }

      subject { get '/api/v3/locations/locate', params: { coords: "#{lat},#{lng}" } }

      it 'should respond with the closest location' do
        expect(Location).to receive(:nearest_to_coords).with(
          latitude: lat.to_s,
          longitude: lng.to_s
        ).and_return(
          [location]
        )
        subject
        expect(response_json).to match serialized_location(location)
      end
    end

    context 'no coords passed' do
      context 'signed in user' do
        let!(:user) { FactoryGirl.create :user, location: location }
        let(:auth_headers) { auth_headers_for(user) }

        subject do
          get '/api/v3/locations/locate', params: {}, headers: auth_headers
        end

        it "returns the users's location preference" do
          subject
          expect(response_json).to match serialized_location(location)
        end
      end

      context 'not signed in' do
        subject do
          get '/api/v3/locations/locate'
        end

        it 'returns the nearest location to the IP address' do
          request_ip = '127.0.1.2'
          allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return(request_ip)

          expect(Location).to receive(:nearest_to_ip).and_return([location])
          subject
          expect(response_json).to match serialized_location(location)
        end
      end
    end
  end
end
