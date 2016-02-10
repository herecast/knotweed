ThinkingSphinx::Index.define(:business_profile,
  :with => :active_record,
  delta: ThinkingSphinx::Deltas::DatetimeDelta,
  delta_options: { threshold: 1.hour }
) do
  indexes business_categories.name, as: :category_names
  indexes content.title, as: :title
  indexes content.raw_content, as: :content
  indexes business_location.city
  indexes business_location.state
end
