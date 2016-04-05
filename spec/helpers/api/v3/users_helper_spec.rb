require 'spec_helper'

describe Api::V3::UsersHelper, type: :helper do
  describe '#select_weather_icon' do
    it 'returns matching icon name' do
      map = {
        'clear-day' => 'wi-day-sunny',
        'clear-night' => 'wi-night-clear',
        'rain' => 'wi-rain',
        'snow' => 'wi-snow',
        'wind' => 'wi-windy',
        'fog' => 'wi-fog',
        'cloudy' => 'wi-cloudy',
        'partly-cloudy-day' => 'wi-day-cloudy',
        'partly-cloudy-night' => 'wi-night-cloudy'
      }

      map.each do |key, value|
        expect(helper.select_weather_icon(key)).to eq value
      end
    end
  end
end
