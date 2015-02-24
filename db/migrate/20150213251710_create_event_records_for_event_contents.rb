class CreateEventRecordsForEventContents < ActiveRecord::Migration
  def up
    # get all calendar records that were originally listserv posts
    Content.where("start_date IS NOT NULL AND channelized <> 1 AND source_id NOT IN (305,313,314,317,306,307,308,309,310,311,312,315,316,318,319,320,321,322,323,437,424,444)").find_each do |c|
      # skip if content already has an event record in existence
      # shouldn't happen in production, but just in case on dev instances
      # want to be sure we aren't creating multiple content/event pairs 
      if c.event.present?
        next
      end
      # new_content = c.dup
      # our existing contents model has two fields that define the event title and description.
      # we're removing those fields, operating under the new assumption that
      # each real event record maps to a single content record, so its content
      # and title fields need to reflect the "event" fields.
      if c.event_description.present?
        c.raw_content = c.event_description
      end
      if c.event_title.present?
        c.title = c.event_title
      end
      # we want this new record to be flagged as 'channelized'
      c.channelized = true
      c.save
      # we want the original content_record to have a pointer to it's curated version
      #c.update_attribute :channelized_content_id, new_content.id
      # now we create the event record
      e = Event.new content_id: c.id, cost: c.cost,
        venue: c.business_location, featured: c.featured,
        sponsor: c.host_organization,
        sponsor_url: c.sponsor_url, links: c.links
      e.save

      # here, we populate an event_instance record for each event
      ei = EventInstance.create(event_id: e.id, start_date: c.start_date, end_date: c.end_date)
    end
  end

  # because events are required to have a content record associated with them,
  # the only meaningful "down" we can really accomplish is dropping all events.
  def down
    EventInstance.destroy_all
    Event.destroy_all
  end
end
