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

  # NOTE: for some reason, the order of these two lines is VERY IMPORTANT.
  # See this issue: https://github.com/pat/thinking-sphinx/issues/978
  has [locations.id, organization.locations.id], as: :all_loc_ids, multi: true
  has organization.id, as: :org_id

  has published
  has channel_type
  has root_content_category_id
  has content_category_id
  has my_town_only
  has "contents.deleted_at IS NOT NULL", as: :deleted, type: :boolean

  # note, this is used for the Talk index page to query
  # root contents only
  has root_parent_id

  indexes "CASE root_content_category_id WHEN (select id from content_categories where name = 'event') THEN (CASE channel_type WHEN 'Event' THEN 1 ELSE 0 END) ELSE 1 END", as: :in_accepted_category
end
