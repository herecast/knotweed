ThinkingSphinx::Index.define :content, :with => :active_record do
  # fields
  indexes raw_content, as: :content
  indexes title
  indexes subtitle
  indexes authors
  indexes channelized_content_id
  indexes published

  # attributes
  has pubdate
  has content_category.id, as: :cat_ids
  has repositories.id, as: :repo_ids
  has publication.id, as: :pub_id
  has locations.id, as: :loc_ids
  has publication.locations.id, as: :pub_loc_ids
end
