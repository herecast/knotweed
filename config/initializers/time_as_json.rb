# frozen_string_literal: true

# config/initializers/time_as_json.rb
module ActiveSupport
  class TimeWithZone
    def as_json(_options = nil)
      if ActiveSupport::JSON::Encoding.use_standard_json_time_format
        xmlschema
      else
        %(#{time.strftime('%FT%T')}#{formatted_offset(false)})
      end
    end
  end
end
