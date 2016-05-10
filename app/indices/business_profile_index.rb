ThinkingSphinx::Index.define(:business_profile,
  :with => :active_record,
  delta: ThinkingSphinx::Deltas::DatetimeDelta,
  delta_options: { threshold: 1.hour }
) do

  set_property :min_prefix_len => 1

  indexes business_categories.name, as: :category_names
  indexes content.title, as: :title
  indexes content.raw_content, as: :content
  indexes business_location.city
  indexes business_location.state

  has "RADIANS(business_locations.latitude)",  :as => :latitude,  :type => :float
  has "RADIANS(business_locations.longitude)", :as => :longitude, :type => :float
  has business_categories.id, as: :category_ids, multi: true
  has content.organization.name, as: :organization_name
  has feedback_count, as: :feedback_count
  has feedback_satisfaction_avg, as: :feedback_satisfaction_avg
  has feedback_price_avg, as: :feedback_price_avg
  has feedback_recommend_avg, as: :feedback_recommend_avg
  has feedback_cleanliness_avg, as: :feedback_cleanliness_avg
  has content.organization_id, as: :organization_id
  has archived, as: :archived
  has 'IF(existence IS NULL OR existence >= 0.4, 1, 0)', as: :exists, type: :boolean
end
