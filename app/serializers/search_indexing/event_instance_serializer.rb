# frozen_string_literal: true

module SearchIndexing
  class EventInstanceSerializer < ActiveModel::Serializer
    attributes :id, :start_date, :end_date, :subtitle_override, :description_override, :presenter_name
  end
end
