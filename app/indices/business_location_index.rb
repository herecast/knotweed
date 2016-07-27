ThinkingSphinx::Index.define(:business_location, 
  :with => :active_record,
  delta: ThinkingSphinx::Deltas::DatetimeDelta,
  delta_options: { threshold: 1.hour }
) do
  indexes :name, sortable: true
  indexes :city
  indexes :state
  indexes :status
  has :status, as: :status_attr

  set_property :min_prefix_len => 1

  has :created_by
end
