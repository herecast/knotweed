module Api
  module V3
    module HashieMashes
      class ContentLocationSerializer < ::HashieMashSerializer
        attributes :id, :location_id, :location_type, :location_name

        def location_id
          object.location.slug
        end

        def location_name
          object.location.name
        end
      end
    end
  end
end
