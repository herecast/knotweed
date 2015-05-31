ThinkingSphinx::Index.define :business_location, :with => :active_record do
  indexes :name
  indexes :city
  indexes :state

  set_property :min_infix_len => 3
  set_property :enable_star   => true
end
