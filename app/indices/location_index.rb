ThinkingSphinx::Index.define :location, with: :active_record do
  indexes :city
  indexes :state

  set_property :min_prefix_len => 1
  set_property :enable_star => true

  where 'consumer_active = true'
end
