ThinkingSphinx::Index.define :content, :with => :active_record do
  # fields
  indexes content
  indexes title
  indexes subtitle
  indexes authors
  indexes subtitle

  # attributes
  has timestamp
  has content_category.id, as: :cat_ids
  has repositories.id, as: :repo_ids
  has source.id, as: :pub_id
end
