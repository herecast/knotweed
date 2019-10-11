# frozen_string_literal: true

module SearchIndexing
  class OrganizationSerializer < ::Api::V3::OrganizationSerializer
    attributes :archived,
      :content_categories

    def content_categories
      object.contents_content_categories_only.map(&:content_category).uniq
    end
  end
end
