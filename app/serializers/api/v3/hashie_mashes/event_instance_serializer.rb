module Api
  module V3
    module HashieMashes
      class EventInstanceSerializer < HashieMashSerializer
        attributes :id, :subtitle, :starts_at, :ends_at, :presenter_name

        def starts_at
          object.start_date
        end

        def ends_at
          object.end_date
        end

        def subtitle
          object.subtitle_override
        end
      end
    end
  end
end
