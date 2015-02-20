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
  end

  def update
  end

  def edit
  end

  def new
  end
end
