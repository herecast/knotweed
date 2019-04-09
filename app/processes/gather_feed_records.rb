# frozen_string_literal: true

class GatherFeedRecords
  def self.call(*args)
    new(*args).call
  end

  def initialize(params:, current_user:)
    @params          = params
    @current_user    = current_user
    update_content_type
  end

  def call
    return empty_payload if org_present_and_biz_feed_inactive?

    do_search if @params[:content_type] != 'organization'
    create_content_array
    conditionally_add_carousels
    { records: @records, total_entries: @total_entries }
  end

  private

  def update_content_type
    if @params[:content_type] == 'stories' || @params[:content_type] == 'posts'
      @params[:content_type] = 'news'
    elsif @params[:content_type] == 'calendar'
      @params[:content_type] = 'event'
    end
  end

  def do_search
    @contents = Content.search(query, content_opts)
    @total_entries = @contents.total_entries
    assign_first_served_at_to_new_contents
  end

  def create_content_array
    if @params[:content_type] == 'organization'
      organizations = Organization.search(query, organization_opts)
      @total_entries = organizations.total_entries
    end
    @records = (organizations || @contents).map do |item|
      FeedItem.new(item)
    end
  end

  def conditionally_add_carousels
    if first_page_of_standard_search_request?
      %w[Publishers Businesses].each do |type|
        carousel = Carousels::OrganizationCarousel.new(title: type, query: query)
        if carousel.organizations.count > 0
          @records.insert(0, FeedItem.new(carousel))
        end
      end
    end
  end

  def content_opts
    if organization_calendar_view?
      ContentSearch.organization_calendar_query(params: @params)
    else
      ContentSearch.standard_query(
        params: @params,
        current_user: @current_user
      )
    end
  end

  def organization_opts
    {
      page: page,
      per_page: per_page,
      where: {
        org_type: %w[Blog Publisher Publication Business]
      }
    }
  end

  def page
    @params[:page].present? ? @params[:page].to_i : 1
  end

  def per_page
    @params[:per_page] || 20
  end

  def query
    @params[:query].present? ? @params[:query] : '*'
  end

  def empty_payload
    { records: [], total_entries: 0 }
  end

  def org_present_and_biz_feed_inactive?
    return false unless @params[:organization_id].present?

    organization = Organization.find(@params[:organization_id])
    organization.org_type == 'Business' && !organization.biz_feed_active
  end

  def first_page_of_standard_search_request?
    @params[:query].present? &&
      @params[:content_type] != 'organization' &&
      @params[:organization_id].blank? &&
      page == 1
  end

  def assign_first_served_at_to_new_contents
    BackgroundJob.perform_later('ManageContentOnFirstServe', 'call',
                                content_ids: @contents.map(&:id),
                                current_time: Time.current.to_s)
  end

  def organization_calendar_view?
    @params[:organization_id].present? && @params[:content_type] == 'event'
  end
end
