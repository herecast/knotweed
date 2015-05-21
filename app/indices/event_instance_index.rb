ThinkingSphinx::Index.define :event_instance, :with => :active_record, delta: true do
  # fields
  indexes event.content.raw_content, as: :content
  indexes event.content.title, as: :title
  indexes [event.venue.name, event.venue.city, event.venue.state]
  indexes event.event_category, as: :event_category, delta: true
  indexes subtitle_override

  has event.content.pubdate
  has start_date
  has event.content.locations.id, as: :loc_ids
end
