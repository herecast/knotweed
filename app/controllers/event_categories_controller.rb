class EventCategoriesController < ApplicationController

  def index
    @event_categories = EventCategory.alphabetical
  end

  def new
    @event_category = EventCategory.new
  end

  def create
    @event_category = EventCategory.new(event_category_params)
    if @event_category.save
      redirect_to event_categories_path, notice: "Event category created"
    else
      render 'new'
    end
  end

  def edit
    @event_category = EventCategory.find(params[:id])
  end

  def update
    @event_category = EventCategory.find(params[:id])
    if @event_category.update_attributes(event_category_params)
      redirect_to event_categories_path, notice: "Event category #{@event_category.name} has been updated"
    else
      render 'edit'
    end
  end

  def destroy
    @event_category = EventCategory.find(params[:id])
    @event_category.destroy
    redirect_to event_categories_path, notice: "Event category #{@event_category.name} has been deleted"
  end

  private

    def event_category_params
      params.require(:event_category).permit(
        :name,
        :query,
        :query_modifier
      )
    end

end
