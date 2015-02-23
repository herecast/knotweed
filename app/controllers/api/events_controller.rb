class Api::EventsController < Api::ApiController

  def update
    @event = Event.find(params[:id])
    # legacy handling of event_description and event_title fields
    params[:event][:title] = params[:event].delete :event_title if params[:event][:event_title].present?
    params[:event][:description] = params[:event].delete :event_description if params[:event][:event_description].present?

		# handle images
		if params[:event][:image].present?
			hImage = params[:event].delete :image
			image_temp_file = Tempfile.new('tmpImage')
			image_temp_file.puts hImage[:image_content]
			file_to_upload = ActionDispatch::Http::UploadedFile.new(tempfile: image_temp_file,
				                                                      filename: hImage[:image_name], type: hImage[:image_type])
			@image = Image.new
			@image.image = file_to_upload
		end

		if @event.update_attributes(params[:event])
      if @image.present?
        # would just do @event.images << @image, but despite the fact
        # that we are set up to have more than one image per content,
        # on the consumer side, we're assuming there's only one image.
        # So to ensure we're displaying the right one, we have to do this.
        @event.images = [@image]
        @event.save
      end
			render text: "#{@event.id}"
		else
			render text: "update of event #{@event.id} failed", status: 500
		end
  end

  # event creation is somewhat different from content creation in that we don't need
  # any of the weird hacky hard-coded category based logic (mostly revolving around "beta_talk")
  #
  # the source is also handled differently, and reverse publishing can be done to multiple sources
  # simultaneously to creating and publishing our original content
  def create
    source = params[:event].delete :source
    pub = Publication.find_by_name(source)

    cat_name = params[:event].delete :category
    cat = ContentCategory.find_or_create_by_name(cat_name) unless cat_name.nil?

    # destinations for reverse publishing
    destinations = params[:event].delete :destinations

    start_date = params[:event].delete(:start_date)
    venue_id = params[:event].delete(:business_location_id)

    # TODO: there has got to be a better way! but I tried simply piping the image straight through
    # and allowing mass assignment to upload it as you would a normal form submission and no dice, so using
    # JS's solution until we think of something better.
    if params[:event][:image].present?
      img = params[:event].delete :image
	    image_temp_file = Tempfile.new('tmpImage')
	    image_temp_file.puts img[:image_content]
	    file_to_upload = ActionDispatch::Http::UploadedFile.new(tempfile: image_temp_file,
			                    filename: img[:image_name], type: img[:image_type])
      event_image = Image.new image: file_to_upload
    end

    # create content record to associate with the new event record
    content_record = Content.new
    content_record.title = params[:event].delete(:title)
    content_record.raw_content = params[:event].delete(:event_description)
    content_record.authors = params[:event].delete(:authors)
    content_record.authoremail = params[:event].delete(:authoremail)
    content_record.images = [event_image] if event_image.present?
    content_record.content_category = cat
    content_record.source = pub
    content_record.pubdate = content_record.timestamp = Time.zone.now

#    instance = EventInstance.new params[:event][:event_instances]

    @event = Event.new(content: content_record, venue_id: venue_id, featured: 0)
    @event.event_instances.new params[:event][:event_instances]

    if @event.save

      # reverse publish to specified destinations
      if destinations.present?
        destinations.each do |d|
          next if d.empty?
          dest_pub = Publication.find_by_name(d)
          # skip if it doesn't exist or if it can't reverse publish
          next if dest_pub.nil? or !dest_pub.can_reverse_publish
          ReversePublisher.send_event_to_listserv(@event, dest_pub, @requesting_app).deliver
          logger.debug(dest_pub.name)
        end
      end

      repo = Repository.find_by_dsp_endpoint(params[:repository])
      if repo.present? and params[:publish] == "true"
        if @event.publish(Content::POST_TO_NEW_ONTOTEXT, repo)
          render text: "#{@event.id}"
        else
          render text: "Event #{@event.id} created but failed to publish", status: 500
        end
      end
    else
      render text: "Event could not be created", status: 500
    end

  end

end
