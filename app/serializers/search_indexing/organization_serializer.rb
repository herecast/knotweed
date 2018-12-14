module SearchIndexing
  class OrganizationSerializer < ActiveModel::Serializer
    attributes :id, :name, :profile_image_url, :biz_feed_active
  end
end
