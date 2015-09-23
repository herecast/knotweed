module Api::V3::UsersHelper

  def select_weather_icon(forecastio_icon)
    # possible icon values from forecast_id:
    # clear-day, clear-night, rain, snow, sleet, wind, fog, cloudy, partly-cloudy-day, or partly-cloudy-night

    icon_map = {}
    icon_map['clear-day'] = 'wi-day-sunny'
    icon_map['clear-night'] = 'wi-night-clear'
    icon_map['rain'] = 'wi-rain'
    icon_map['snow'] = 'wi-snow'
    icon_map['wind'] = 'wi-windy'
    icon_map['fog'] = 'wi-fog'
    icon_map['cloudy'] = 'wi-cloudy'
    icon_map['partly-cloudy-day'] = 'wi-day-cloudy'
    icon_map['partly-cloudy-night'] = 'wi-night-cloudy'

    wi_icon = icon_map[forecastio_icon]
    wi_icon ||= 'wi-cloudy'
  end

end
