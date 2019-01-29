# frozen_string_literal: true

class ContentsController < ApplicationController
  def index
    expires_in 1.minutes, public: true
    # if posted, save to session
    if params[:reset]
      session[:contents_search] = nil
    elsif params[:q].present?
      if params[:q][:id_in].present?
        params[:q][:id_in] = params[:q][:id_in].split(',').map(&:strip)
      end
      params[:q][:s] = 'pubdate desc' unless params[:q][:s].present?
      session[:contents_search] = params[:q]
    end

    @content_categories = ContentCategory.all
    @locations = Location.accessible_by(current_ability).consumer_active.order('state ASC, city ASC')

    search_conditions = session[:contents_search].try(:dup) || {}
    search_conditions[:content_category_id_not_eq] = ContentCategory.find_by_name('campaign').try(:id)

    if search_conditions[:event_instances_start_date_gteq].present? || search_conditions[:event_instances_end_date_lteq].present?
      search_conditions[:channel_type_eq] = 'Event'
    end

    @search = Content.ransack(search_conditions)

    if session[:contents_search].present?
      @contents = @search.result(distinct: true)
                         .includes(:organization, :created_by, :content_category, :root_content_category, :channel)
                         .order('pubdate DESC').page(params[:page])
                         .per(100)
    else
      @contents = []
    end
  end

  def edit
    @news_child_ids = ContentCategory.where(parent_id: 31).pluck(:id)
    @content = Content.includes(:location, :content_category).find(params[:id])
    load_event_instances
    authorize! :edit, @content
  end

  def update
    @content = Content.find(params[:id])
    if @content.update_attributes(content_params)
      flash[:notice] = "Successfully updated content #{@content.id}"
      if params[:continue_editing]
        redirect_to edit_content_path(@content)
      else
        redirect_to contents_path
      end
    else
      load_event_instances
      render 'edit'
    end
  end

  def destroy
    @content = Content.find params[:id]
    authorize! :destroy, @content
    @content.destroy
    respond_to do |format|
      format.js
    end
  end

  def parent_select_options
    # check if search query is an integer; if it is, use it as ID query, otherwise title
    if params[:search_query].to_i.to_s == params[:search_query]
      params[:q][:id_eq] = params.delete :search_query
    else
      params[:q][:title_cont] = params.delete :search_query
    end
    conts = Content.ransack(params[:q]).result(distinct: true).order('pubdate DESC').limit(100)
    if params[:content_id].present?
      @orig_content = Content.find(params[:content_id])
      conts -= [@orig_content]
    end
    @contents = conts.map { |c| [c.title, c.id] }.insert(0, nil)
    respond_to do |format|
      format.js
    end
  end

  private

  def load_event_instances
    if @content.channel_type == 'Event'
      @event_instances = @content.event.event_instances.page(params[:page] || 1).per(10)
    end
  end

  def content_params
    params.require(:content).permit(
      :title,
      :content_category_id,
      :organization_id,
      :category_reviewed,
      :has_event_calendar,
      :subtitle,
      :authors,
      :parent_id,
      :pubdate,
      :url,
      :banner_ad_override,
      :sanitized_content,
      :raw_content,
      :alternate_title,
      :alternate_organization_id,
      :alternate_authors,
      :alternate_text,
      :alternate_image_url,
      :location_id,
      organization_ids: [],
      similar_content_overrides: [],
      event_attributes: %i[
        id
        event_url
        contact_phone
        contact_email
        event_category
        cost_type
        cost
        registration_deadline
      ],
      market_post_attributes: %i[
        id
        cost
        contact_phone
        contact_email
      ]
    )
  end

end
