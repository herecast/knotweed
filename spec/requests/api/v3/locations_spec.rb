require 'rails_helper'

def serialized_location location
  {
    location: {
      id: location.slug,
      city: location.city,
      state: location.state
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

        expect(response_json[:locations].find{|l| l[:id].eql? location.slug}).to match serialized
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
      subject { get '/api/v3/locations/' + "123-not-valid" }

      it 'responds with 404 status code' do
        subject
        expect(response_json).to match Hash.new #empty hash payload
        expect(response.code).to eql "404"
      end
    end
  end

  describe 'GET /api/v3/locations/locate' do
    let!(:other_locations) { FactoryGirl.create_list :location, 3 }
    let(:location) { FactoryGirl.create :location }

    context 'with coords passed' do
      let(:lat) { Faker::Address.latitude }
      let(:lng) { Faker::Address.longitude }

      subject { get '/api/v3/locations/locate', coords: "#{lat},#{lng}" }

      it 'should respond with the closest location' do
        expect(Location).to receive(:nearest_to_coords).with(
          latitude: lat,
          longitude: lng
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

        subject {
          get '/api/v3/locations/locate', {}, auth_headers
        }

        it "returns the users's location preference" do
          subject
          expect(response_json).to eql serialized_location(location)
        end
      end

      context 'not signed in' do
        subject {
          get '/api/v3/locations/locate'
        }

        it 'returns the nearest location to the IP address' do
          request_ip = '127.0.1.2'
          allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return(request_ip)

          expect(Location).to receive(:nearest_to_ip).and_return([location])
          subject
          expect(response_json).to eql serialized_location(location)
        end
      end
    end
  end
end
