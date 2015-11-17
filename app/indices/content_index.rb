ThinkingSphinx::Index.define(:content, 
  with: :active_record,
  delta: ThinkingSphinx::Deltas::DatetimeDelta,
  delta_options: { threshold: 1.hour }
) do
  # fields
  indexes raw_content, as: :content
  indexes title
  indexes subtitle
  indexes authors

  # attributes
  has pubdate
  has publication.id, as: :pub_id
  has [locations.id, publication.locations.id], as: :all_loc_ids, multi: true

  has published
  has channel_type
  has root_content_category_id

  # conditions
  where "IF(root_content_category_id = (select id from content_categories where name = 'event'), channel_type = 'Event', true)"
end
