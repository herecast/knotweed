class EventsController < ApplicationController

  # It turns out -- after coding this controller -- that they actually want every event instance
  # to show up in a row. So, this search action actually happens on event indices. Which has a 
  # side effect of making our query parameters REALLY long, but that's ok.
  def index
    # if posted, save to session
    if params[:reset]
      session[:events_search] = nil
    elsif params[:q].present?
      if params[:q][:event_content_id_in].present?
        params[:q][:event_content_id_in] = params[:q][:event_content_id_in].split(',').map{ |s| s.strip }
      end
      session[:events_search] = params[:q]
    end
    
    @search = EventInstance.ransack(session[:events_search])

    if session[:events_search].present?
      @event_instances = @search.result(distinct: true).joins(event: :content).order("start_date DESC").page(params[:page]).per(100)
      @event_instances = @event_instances.accessible_by(current_ability)
    else
      @event_instances = []
    end
  end

  def create

    # clean up the event instance data
    instances = []
    params[:event][:event_instances_attributes].each do |instance|
      process_instance_date_params(instance[1])
      instances << instance[1]
    end
    params[:event][:event_instances_attributes] = instances

    @event = Event.new(params[:event])
    authorize! :create, @event
    if @event.save!
      # if this was curated from an existing content record, we need to update
      # that content record to reflect that
      if params[:unchannelized_content_id].present?
        @curated = true # for form_submit_rediret_path
        unchan_content = Content.find params[:unchannelized_content_id]
        unchan_content.update_attributes channelized_content_id: @event.content.id, has_event_calendar: true
        # make a copy of the original image if it exists and if
        # the new event/content was created without uploading a new image
        if unchan_content.images.present? and @event.images.empty?
          original_image = unchan_content.images.first
          @event.content.images << Image.create(image: original_image.image, source_url: original_image.source_url,
                                               caption: original_image.caption, credit: original_image.credit)
          # we need to make a copy of the image in its new path
          connection = Fog::Storage.new({
            provider: "AWS",
            aws_access_key_id: Figaro.env.aws_access_key_id,
            aws_secret_access_key: Figaro.env.aws_secret_access_key
          })
          old_path = original_image.image.path.to_s
          new_path = @event.content.images.first.image.path.to_s
          connection.copy_object(Figaro.env.aws_bucket_name, old_path, Figaro.env.aws_bucket_name, new_path)
        end
      end
      if current_user.default_repository.present?
         publish_success = @event.content.publish(Content::POST_TO_NEW_ONTOTEXT, current_user.default_repository)
      end

      flash[:notice] = "Created event with id #{@event.id}"
      if publish_success == true
        flash[:notice] = flash[:notice] + " and published successfully"
      elsif publish_success == false
        flash[:warning] = "Publish failed"
      end
      redirect_to form_submit_redirect_path(@event.id)
    else
      render "new"
    end
  end

  def update
    # ensure serialized values are set to empty if no fields are passed in via form
    if params[:event].present?
      params[:event][:links] = nil unless params[:event].has_key? :links
    end

    # clean up the event instance data
    instances = []
    params[:event][:event_instances_attributes].each do |instance|
      process_instance_date_params(instance[1])
      instances << instance[1]
    end
    params[:event][:event_instances_attributes] = instances

    @event = Event.find(params[:id])
    authorize! :update, @event

    if @event.update_attributes(params[:event])
      # re-publish updated content
      if current_user.default_repository.present?
         publish_success = @event.content.publish(Content::POST_TO_NEW_ONTOTEXT, current_user.default_repository)
      end
      flash[:notice] = "Successfully updated event #{@event.id}"
      if publish_success == true
        flash[:notice] = flash[:notice] + " and re-published"
      elsif publish_success == false
        flash[:warning] = "Publish failed"
      end
      redirect_to form_submit_redirect_path(@event.id)
    else
      render "edit"
    end
  end

  def edit
    # need to determine id of "next record" if we got here from the search index
    if params[:index].present?
      params[:page] = 1 unless params[:page].present?
      events = EventInstance.ransack(session[:events_search]).result(distinct: true).joins(event: :content).order("event_instances.start_date DESC").page(params[:page]).per(100).select("events.id")
      @next_index = params[:index].to_i + 1
      @next_event_id = events[@next_index].try(:id)
      # account for scenario where we are at end of page
      if @next_event_id.nil?
        params[:page] = params[:page].to_i + 1
        events = EventInstance.ransack(session[:events_search]).result(distinct: true).joins(event: :content).order("event_instances.start_date DESC").page(params[:page]).per(100).select("events.id")
        @next_index = 0 # first one on the new page
        @next_event_id = events[@next_index].try(:id)
      end
    end
    @event = Event.find(params[:id])
    @event.content.images.build if @event.content.images.empty?
    authorize! :edit, @event
  end

  def new
    @event = Event.new
    # if this is curating an existing piece of content, we get passed "unchannelized_content_id"
    # and use that to construct our new content
    if params[:unchannelized_content_id].present?
      unchannelized_content = Content.find(params[:unchannelized_content_id])
      @event.content = unchannelized_content.dup
      # we pass in a placeholder for the image url so that we can display it
      # (if the original content had an image),
      # then in create we duplicate the original image and assign it to the new content.
      @placeholder_image = unchannelized_content.images.first
      @event.content.title = remove_list_from_title(unchannelized_content.title)
    else
      @event.content = Content.new
    end

    @event.content.images.build unless @event.content.images.present?
    @event.event_instances.build

    # set default fields for event channelized content here
    
    # for the record, I hate this. That we're hard coding "event" which is represented by a database
    # field *throughout* the codebase. It's done under protest.
    @event.content.content_category_id = ContentCategory.find_or_create_by_name("event").id

    # hard coding some other things
    @event.content.category_reviewed = true
    # again with the under protest...
    @event.content.source_id = Publication.find_or_create_by_name("Subtext Events").id

    # for users that can only access certain specific attribute events
    current_ability.attributes_for(:new, Event).each do |key,value|
      @event.send("#{key}=", value)
    end
    authorize! :new, @event
  end

  private

  def form_submit_redirect_path(id=nil)
    if params[:continue_editing]
      edit_event_path(id)
    elsif params[:create_new]
      new_event_path
    elsif params[:next_record]
      edit_event_path(params[:next_record_id], index: params[:index], page: params[:page])
    elsif @curated == true
      contents_path
    else
      events_path
    end
  end

  def process_instance_date_params(event_instance)
    if event_instance.has_key? :start_day and event_instance.has_key? :start_time
      Chronic.time_class = Time.zone
      event_instance[:start_date] = (Chronic.parse(event_instance[:start_day] + " " + event_instance[:start_time])).to_s
      # if end time is specified, but no end day, use start day
      # if (event_instance[:end_time].present? or event_instance[:end_time].blank?)
      if (event_instance[:end_time].present?)
        event_instance[:end_day] = event_instance[:start_day]
        event_instance[:end_date] = (Chronic.parse(event_instance[:end_day] + " " + event_instance[:end_time])).to_s
      end

      # clean up unneeded stuff
      event_instance.delete(:start_day)
      event_instance.delete(:start_time)
      event_instance.delete(:end_day)
      event_instance.delete(:end_time)
    end
  end

  def remove_list_from_title(title)
    if title.present?
      title.gsub(/\[.*\]/, '')
    else
      nil
    end
  end


end
