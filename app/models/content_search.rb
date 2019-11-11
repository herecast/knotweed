# frozen_string_literal: true

class ContentSearch
  def self.standard_query(*args)
    new(*args).standard_query
  end

  def self.caster_follows_query(*args)
    new(*args).caster_follows_query
  end

  def self.caster_query(*args)
    new(*args).caster_query
  end

  def self.calendar_query(*args)
    new(*args).calendar_query
  end

  def self.comment_query(*args)
    new(*args).comment_query
  end

  def initialize(params:, current_user: nil)
    @params         = params
    @current_user   = current_user
  end

  def standard_query
    update_content_types_in_params
    standard_opts.tap do |attrs|
      add_boilerplate_opts(attrs)
      whitelist_content_type(attrs)
      conditionally_add_location_opts(attrs)
      conditionally_update_boost_for_query(attrs)
      conditionally_guard_from_future_latest_activity(attrs)
    end
  end

  # returns content that has been commented on by the current user
  def comment_query
    standard_opts.tap do |attrs|
      attrs[:where][:commented_on_by_ids] = { in: @params[:id] }
    end
  end

  def caster_query
    standard_query.tap do |attrs|
      if @params[:liked] == 'true'
        attrs[:where][:id] = { in: Like.where(user_id: @params[:id]).pluck(:content_id) }
      else
        attrs[:where][:created_by_id] = @params[:id]
      end
      conditionally_update_for_drafts(attrs)
    end
  end

  def conditionally_update_for_drafts(attrs)
    if [true, 'true'].include?(@params[:drafts])
      attrs[:where].delete(:pubdate)
      attrs[:where][:or] << [
        { pubdate: nil },
        { pubdate: { gt: Time.current } }
      ]
    end
  end

  def caster_follows_query
    standard_query.tap do |attrs|
      following_ids = @current_user.caster_follows.map(&:caster_id).flatten
      attrs[:where][:created_by_id] = following_ids
      attrs[:where].delete(:location_id)
    end
  end

  def calendar_query
    {
      load: false,
      page: page,
      per_page: per_page,
      where: {
        content_type: 'event',
        biz_feed_public: [true, nil],
        starts_at: starts_at_range,
        removed: {
          not: true
        }
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
        attrs[:where][:created_by_id] = {
          not: @current_user.blocked_caster_ids
        }
      end
    end
  end

  def add_boilerplate_opts(attrs)
    attrs[:where][:or] = [category_options]
  end

  def category_options
    content_types = %w[news talk]
    content_types += %w[market] if should_include_market_posts?
    if @params[:calendar] == 'false'
      [{ content_type: content_types }]
    else
      [{ content_type: content_types + %w[event] }]
    end
  end

  def should_include_market_posts?
    @params[:content_type].present? || \
      @params[:query].present? || \
      @params[:caster] == true
  end

  def whitelist_content_type(attrs)
    if @params[:content_type].present?
      attrs[:where][:content_type] = @params[:content_type]
    end
  end

  def conditionally_add_location_opts(attrs)
    if location.present?
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

  def conditionally_guard_from_future_latest_activity(attrs)
    unless @params[:id].present?
      attrs[:where][:latest_activity] = { lt: Time.current + 10.minutes }
    end
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

  def starts_at_range
    if end_date.present?
      start_date.beginning_of_day..end_date.end_of_day
    else
      { gte: start_date }
    end
  end

  def start_date
    @params[:start_date].present? ? DateTime.parse(@params[:start_date]) : DateTime.now
  end

  def end_date
    @params[:end_date].present? ? DateTime.parse(@params[:end_date]) : nil
  end
end
