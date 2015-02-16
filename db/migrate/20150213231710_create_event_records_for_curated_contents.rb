class CreateEventRecordsForCuratedContents < ActiveRecord::Migration
  def up
    Content.where("start_date IS NOT NULL").find_each do |c|
      # skip if content already has an event record in existence
      if c.event.present?
        next
      end
      new_content = c.dup
      # our existing contents model has two fields that define the event title and description.
      # we're removing those fields, operating under the new assumption that
      # each real event record maps to a single content record, so its content
      # and title fields need to reflect the "event" fields.
      if new_content.event_description.present?
        new_content.raw_content = new_content.event_description
      end
      if new_content.event_title.present?
        new_content.title = new_content.event_title
      end
      new_content.save
      e = Event.new content_id: new_content.id, cost: new_content.cost, start_date: new_content.start_date,
        venue: new_content.business_location, featured: new_content.featured,
        end_date: new_content.end_date, sponsor: new_content.host_organization,
        sponsor_url: new_content.sponsor_url, links: new_content.links
      e.save
    end
  end

  # because events are required to have a content record associated with them,
  # the only meaningful "down" we can really accomplish is dropping all events.
  def down
    Event.destroy_all
  end
end
