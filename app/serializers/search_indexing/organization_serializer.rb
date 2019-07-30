# frozen_string_literal: true

module SearchIndexing
  class OrganizationSerializer < ::Api::V3::OrganizationSerializer
    attributes :archived,
      :content_category_ids

    def content_category_ids
      object.contents_root_content_category_ids_only.map(&:root_content_category_id).uniq
    end
  end
end
