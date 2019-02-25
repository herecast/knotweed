# frozen_string_literal: true

class ContentSearch
  def self.standard_query(*args)
    new(*args).standard_query
  end

  def self.comment_query(*args)
    new(*args).comment_query
  end

  def self.my_stuff_query(*args)
    new(*args).my_stuff_query
  end

  def self.organization_calendar_query(*args)
    new(*args).organization_calendar_query
  end

  def initialize(params:, current_user: nil)
    @params         = params
    @current_user   = current_user
  end

  def standard_query
    update_content_types_in_params
    standard_opts.tap do |attrs|
      add_boilerplate_opts(attrs)
      whitelist_organizations_and_content_types(attrs)
      conditionally_add_location_opts(attrs)
      conditionally_update_attributes_for_organization_query(attrs)
      conditionally_update_boost_for_query(attrs)
      conditionally_guard_from_future_latest_activity(attrs)
    end
  end

  def my_stuff_query
    standard_query.tap do |attrs|
      if @params[:bookmarked] == 'true'
        attrs[:where][:id] = { in: UserBookmark.where(user_id: @params[:id]).pluck(:content_id) }
      else
        attrs[:where][:created_by_id] = @params[:id]
      end
    end
  end

  def comment_query
    standard_opts.tap do |attrs|
      attrs[:where].delete(:pubdate)
      attrs[:where][:content_type] = 'comment'
      attrs[:where][:created_by_id] = @params[:id]
    end
  end

  def organization_calendar_query
    organization = Organization.find(@params[:organization_id])
    {
      load: false,
      page: page,
      per_page: per_page,
      where: {
        content_type: :event,
        biz_feed_public: [true, nil],
        starts_at: {
          gte: Time.current
        },
        removed: {
          not: true
        },
        or: [[
          { organization_id: @params[:organization_id] },
          { id: organization.tagged_contents.pluck(:id) }
        ]]
      },
      order: {
        starts_at: :asc
      }
    }
  end

  private

  def update_content_types_in_params
    if @params[:content_type] == 'stories' || @params[:content_type] == 'posts'
      @params[:content_type] = 'news'
    elsif @params[:content_type] == 'calendar'
      @params[:content_type] = 'event'
    end
  end

  def standard_opts
    {
      load: false,
      order: {
        latest_activity: :desc
      },
      page: page,
      per_page: per_page,
      where: {
        pubdate: 5.years.ago..Time.zone.now,
        removed: {
          not: true
        }
      }
    }.tap do |attrs|
      if @current_user
        attrs[:where][:organization_id] = {
          not: @current_user.blocked_organzation_ids
        }
      end
    end
  end

  def add_boilerplate_opts(attrs)
    attrs[:where][:or] = [category_options]
  end

  def category_options
    content_types = %w[news market talk]
    content_types << 'campaign' if @params[:organization_id].present?
    if @params[:calendar] == 'false'
      [{ content_type: content_types }]
    else
      [
        { content_type: content_types },
        { content_type: 'event', 'organization_id' => { not: Organization::LISTSERV_ORG_ID } }
      ]
    end
  end

  def whitelist_organizations_and_content_types(attrs)
    if @params[:content_type].present?
      attrs[:where][:content_type] = @params[:content_type]
    elsif attrs[:where][:organization_id].present?
      attrs[:where][:organization_id][:not] << Organization::LISTSERV_ORG_ID
    else
      attrs[:where][:organization_id] = { not: Organization::LISTSERV_ORG_ID }
    end
  end

  def conditionally_add_location_opts(attrs)
    if location.present? && @params[:organization_id].blank?
      attrs[:where][:location_id] = { in: location.send(radius_method) }
    end
  end

  def conditionally_update_boost_for_query(attrs)
    if @params[:query].present?
      attrs.delete(:order)
      attrs[:boost_by_distance] = {
        field: :created_at,
        origin: Time.zone.now,
        scale: '60d',
        offset: '7d',
        decay: 0.25
      }
    end
  end

  def conditionally_update_attributes_for_organization_query(attrs)
    if @params[:organization_id].present?
      attrs[:where][:biz_feed_public] = [true, nil]
      organization = if @params[:organization_id] == 'false'
                       Organization.find_by(standard_ugc_org: true)
                     else
                       Organization.find(@params[:organization_id])
                     end

      or_opts = [{ organization_id: organization.id }]
      if @params[:calendar] == 'false'
        or_opts << { id: organization.tagged_contents.where.not(channel_type: 'Event').pluck(:id) }
      else
        or_opts << { id: organization.tagged_contents.pluck(:id) }
      end
      attrs[:where][:or] << or_opts

      attrs[:where][:or] << [
        { sunset_date: nil },
        { sunset_date: { gt: Date.current } }
      ]

      organization_show_options[@params['show']].call(attrs) if @params['show'].present?

      attrs[:order] = { organization_order_moment: :desc }
    end
  end

  def conditionally_guard_from_future_latest_activity(attrs)
    unless @params[:organization_id].present? || @params[:id].present?
      attrs[:where][:latest_activity] = { lt: Time.current + 10.minutes }
    end
  end

  def organization_show_options
    {
      'everything' => ->(attrs) { %i[pubdate biz_feed_public].each { |k| attrs[:where].delete(k) } },
      'hidden' => ->(attrs) { attrs[:where][:biz_feed_public] = false },
      'draft' => lambda do |attrs|
        attrs[:where].delete(:pubdate)
        attrs[:where][:or] << [
          { pubdate: nil },
          { pubdate: { gt: Time.current } }
        ]
      end
    }
  end

  def page
    @params[:page].present? ? @params[:page].to_i : 1
  end

  def per_page
    @params[:per_page].present? ? @params[:per_page].to_i : 20
  end

  def location
    @current_user.present? ? @current_user.location : Location.find_by(id: @params[:location_id])
  end

  def radius
    @params[:radius].presence || 'fifty'
  end

  def radius_method
    "location_ids_within_#{radius}_miles".to_sym
  end
end
