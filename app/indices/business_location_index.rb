ThinkingSphinx::Index.define :business_location, :with => :active_record do
  indexes :name, sortable: true
  indexes :city
  indexes :state

  set_property :min_prefix_len => 1
end
