ThinkingSphinx::Index.define :business_location, :with => :active_record do
  # attributes
  indexes name
  indexes city
  indexes state
end
