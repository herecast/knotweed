class Api::EventsController < Api::ApiController

  def featured_events
    @events = Event.where(featured: true).where("start_date >= ?", Date.today).order("start_date ASC")
    if params[:publications].present?
      allowed_pubs = Publication.where(name: params[:publications])
      @events = @events.where(source_id: allowed_pubs)
    end
    if params[:repository].present?
      @events = @events.includes(:repositories).where(repositories: {dsp_endpoint: params[:repository]}) 
    end
    @events = @events.limit(5)
    render "index"
  end

  def index
    if params[:max_results].present? 
      @events = Event.limit(params[:max_results])
    else
      @events = Event
    end
    @events = @events.includes(:source).includes(:content_category).includes(:images).includes(:import_location)

    if params[:sort_order].present? and ['DESC', 'ASC'].include? params[:sort_order] 
      sort_order = params[:sort_order]
    end

    # TODO: this repository filtering stuff is replicated here *and* in the corresponding
    # places in the api/contents controller. Would be neat to abstract it 
    # which would save us a few lines of code and maybe make things a bit clearer.
    if params[:repository].present?
      @events = @events.includes(:repositories).where(repositories: {dsp_endpoint: params[:repository]}) 
    end

    sort_order ||= "ASC"
    @events = @events.order("start_date #{sort_order}")

    # limit query so we're not accidentally rendering thousands of json objects
    @events = @events.limit(1000) unless params[:max_results].present?

    if params[:start_date].present?
      start_date = Chronic.parse(params[:start_date]).beginning_of_day
      @events = @events.where('start_date >= ?', start_date)
    end
    if params[:end_date].present?
      end_date = Chronic.parse(params[:end_date]).end_of_day
      if end_date == start_date
        end_date = start_date.end_of_day
      end
      @events = @events.where('start_date <= ?', end_date)
    end
    if params[:event_type].present?
      @events = @events.where(event_type: params[:event_type])
    end

    # don't return featured events unless they're requested
    unless params[:request_featured].present?
      @events = @events.where(featured: false)
    end
    @events = @events.includes(:business_location)
  end

  def show
    @event = Event.find(params[:id])
    if params[:repository].present? and @event.present?
      repo = @event.repositories.find_by_dsp_endpoint params[:repository]
      @event = nil if repo.nil?
    end
  end

  def update
    @event = Event.find(params[:id])
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
    event_content = Content.new(params[:event])

    @event = Event.new(content: event_content, start_date: start_date)
    @event.images = [event_image] if event_image.present?
    @event.content_category = cat
    @event.source = pub
    @event.pubdate = @event.timestamp = Time.zone.now

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
