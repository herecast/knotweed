ThinkingSphinx::Index.define :content, :with => :active_record do
  # fields
  indexes raw_content, as: :content
  indexes title
  indexes subtitle
  indexes authors

  # attributes
  has pubdate
  has content_category.id, as: :cat_ids
  has repositories.id, as: :repo_ids
  has publication.id, as: :pub_id
end
