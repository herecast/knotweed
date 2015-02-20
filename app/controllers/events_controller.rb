class EventsController < ApplicationController

  def index
    # if posted, save to session
    if params[:reset]
      session[:events_search] = nil
    elsif params[:q].present?
      if params[:q][:id_in].present?
        params[:q][:id_in] = params[:q][:id_in].split(',').map{ |s| s.strip }
      end
      session[:events_search] = params[:q]
    end
    
    @search = Event.ransack(session[:events_search])

    if session[:events_search].present?
      @events = @search.result(distinct: true).joins(:content).order("contents.pubdate DESC").page(params[:page]).per(100)
      @events = @events.accessible_by(current_ability)
    else
      @events = []
    end
  end

  def create
    @event = Event.new(params[:event])
    authorize! :create, @event
    if @event.save!
      # if this was curated from an existing content record, we need to update
      # that content record to reflect that
      if params[:unchannelized_content_id].present?
        unchan_content = Content.find params[:unchannelized_content_id]
        unchan_content.update_attributes channelized_content_id: @event.content.id, has_event_calendar: true
      end
      flash[:notice] = "Created content with id #{@event.id}"
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
    @event = Event.find(params[:id])
    authorize! :update, @event
    if @event.update_attributes(params[:event])
      flash[:notice] = "Successfully updated event #{@event.id}"
      redirect_to form_submit_redirect_path(@event.id)
    else
      render "edit"
    end
  end

  def edit
    # need to determine id of "next record" if we got here from the search index
    if params[:index].present?
      params[:page] = 1 unless params[:page].present?
      events = Event.ransack(session[:events_search]).result(distinct: true).order("pubdate DESC").page(params[:page]).per(100).select("events.id")
      @next_index = params[:index].to_i + 1
      @next_event_id = events[@next_index].try(:id)
      # account for scenario where we are at end of page
      if @next_event_id.nil?
        params[:page] = params[:page].to_i + 1
        events = Event.ransack(session[:events_search]).result(distinct: true).order("pubdate DESC").page(params[:page]).per(100).select("id")
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
    else
      @event.content = Content.new
    end

    # set default fields for event channelized content here
    
    # for the record, I hate this. That we're hard coding "event" which is represented by a database
    # field *throughout* the codebase. It's done under protest.
    @event.content.content_category_id = ContentCategory.find_or_create_by_name("event").id

    # hard coding some other things
    @event.content.category_reviewed = true
    # again with the under protest...
    @event.content.source_id = Publication.find_or_create_by_name("Subtext Events").id

    @event.content.images.build 
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
    else
      events_path
    end
  end

end
