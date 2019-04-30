# frozen_string_literal: true

require 'spec_helper'

describe 'Locations::Finds Endpoints', type: :request do
  describe 'GET /api/v3/locations/locate' do
    context 'When nearest location is not consumer_active = true' do
      let!(:nearest) do
        FactoryGirl.create :location,
                           consumer_active: false,
                           latitude: 0.5,
                           longitude: 0.5
      end
      let!(:nearest_active) do
        FactoryGirl.create :location,
                           consumer_active: true,
                           latitude: 0.8,
                           longitude: 0.8
      end
      let!(:furthest) do
        FactoryGirl.create :location,
                           consumer_active: true,
                           latitude: 1.2,
                           longitude: 1.2
      end

      subject do
        get '/api/v3/locations/locate', params: { coords: '0,0' }
      end

      it 'returns nearest consumer_active location' do
        subject
        expect(assigns(:location)).to eql nearest_active
      end
    end
  end
end