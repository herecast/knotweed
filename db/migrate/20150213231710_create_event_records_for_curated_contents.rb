class CreateEventRecordsForCuratedContents < ActiveRecord::Migration
  def up
    # add contents.channelized_content_id - this will be a pointer from the original record to it's 'curated' one
    add_column :contents, :channelized_content_id, :integer
    add_index :contents, :channelized_content_id
    # add contents.channelized - a boolean to flag 'channelized' content records
    add_column :contents, :channelized, :boolean, default: false
    add_index :contents, :channelized
    # get all calendar records that were originally listserv posts
    Content.where("start_date IS NOT NULL AND channelized <> 1 AND source_id IN (305,313,314,317,306,307,308,309,310,311,312,315,316,318,319,320,321,322,323,437,424,444)").find_each do |c|
      # skip if content already has an event record in existence
      # shouldn't happen in production, but just in case on dev instances
      # want to be sure we aren't creating multiple content/event pairs 
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
      #set certain fields to null
      new_content.authors = nil
      new_content.authoremail = nil
      new_content.copyright = nil
      new_content.authoremail = nil
      #set source_id to 423 (Subtext Events) - [hard coding id, not the best - i know]
      new_content.source_id = 423
      # we want this new record to be flagged as 'channelized'
      new_content.channelized = true
      new_content.save
      # we want the original content_record to have a pointer to it's curated version
      c.update_attribute :channelized_content_id, new_content.id
      # now we create the event record
      e = Event.new content_id: new_content.id, cost: new_content.cost,
        venue: new_content.business_location, featured: new_content.featured,
        sponsor: new_content.host_organization,
        sponsor_url: new_content.sponsor_url, links: new_content.links
      e.save

      # here, we populate an event_instance record for each event
      ei = EventInstance.create(event_id: e.id, start_date: new_content.start_date, end_date: new_content.end_date)
    end
  end

  # because events are required to have a content record associated with them,
  # the only meaningful "down" we can really accomplish is dropping all events.
  def down
    remove_column :contents, :channelized_content_id
    remove_index :contents, :channelized_content_id
    remove_index :contents, :channelized
    remove_column :contents, :channelized
    EventInstance.destroy_all
    Event.destroy_all
  end
end
