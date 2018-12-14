# frozen_string_literal: true

module Api
  module V3
    class AbbreviatedEventInstanceSerializer < ActiveModel::Serializer
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
