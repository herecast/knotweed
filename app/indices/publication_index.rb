ThinkingSphinx::Index.define :publication, :with => :active_record do
  indexes :name, sortable: true

  has consumer_apps.id, as: :consumer_app_ids
  has contents.root_content_category_id, as: :content_category_ids

  set_property :min_prefix_len => 1
  set_property :enable_star   => true
end
