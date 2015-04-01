ThinkingSphinx::Index.define :event_instance, :with => :active_record do
  # fields
  indexes event.content.raw_content, as: :content
  indexes event.content.title, as: :title
  indexes event.venue.address
  indexes event.venue.name
  indexes subtitle_override

  has event.content.pubdate
  has start_date
end
