namespace :wellness do

  require 'csv'

  desc "Import data from sched.org wellness calendar csv file"
  task import: :environment do
    source_path = File.join(File.dirname(__FILE__),'wellness_sessions.csv')

    last_event_name = ''
    cr = {}
    ev = {}
    instances = []
    num_events = 0
    num_instances = 0

    org_id = Organization.find_by_name('DailyUV').id
    category_id = ContentCategory.find_by_name('event').id

    CSV.foreach(source_path, {:headers => true, :header_converters => :symbol, :converters => :all}) do |row|

      ei = {}

      unless last_event_name == row[:name]

        # save the previously created event, if any
        unless cr.empty? and ev.empty?
          save_and_publish(ev, cr, instances)
          num_events += 1
        end

        # reset the temporary variables
        cr = {}
        ev = {}
        instances = []
        last_event_name = row[:name]

        # this is a new event, not just another instance,
        # so capture the content record information including any image
        cr[:title] = row[:name]
        cr[:raw_content] = row[:description]
        cr[:content_category_id] = category_id
        cr[:organization_id] = org_id
        cr[:pubdate] = Time.current
        cr[:location_ids] = [77]
        if row[:media_url].present?
          image = Image.new
          image.remote_image_url = row[:media_url]
          image.source_url = row[:media_url]
          cr[:images] = [image]
        end

        # and the event information
        ev[:cost] = row[:cost] if row[:cost].present?
        ev[:event_url] = row[:rsvp_url] if row[:rsvp_url].present?
        ev[:event_category] = 'wellness'
        ev[:featured] = 0
        ev[:venue_id] = row[:venue_id]
      end

        # and the event instance
        ei[:start_date] = Chronic.parse(row[:event_start])
        ei[:end_date] = Chronic.parse(row[:event_end])
        instances << ei
        num_instances += 1
    end

    save_and_publish(ev, cr, instances)
    num_events += 1

    puts "Published #{num_events} events and #{num_instances} instances"
  end


#  def save_and_publish(ev, cr, instances)
  def save_and_publish(ev, cr, instances)

    output = ''

    # save the record
    ev[:event_instances_attributes] = instances
    ev[:content_attributes] = cr
    event = Event.new(ev)

    if event.save
      output << "#{event.id} (#{event.title}) saved "
      repo = Repository.find(Repository::PRODUCTION_REPOSITORY_ID)
      if repo.present?
        if event.publish(Content::DEFAULT_PUBLISH_METHOD, repo)
          output << 'and published'
        else
          output << 'but failed to publish'
        end
      end
    else
      output << event.title + ' not saved'
    end

    puts output
  end

end
