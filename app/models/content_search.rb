class ContentSearch

  def self.standard_query(*args)
    self.new(*args).standard_query
  end

  def self.comment_query(*args)
    self.new(*args).comment_query
  end

  def self.my_stuff_query(*args)
    self.new(*args).my_stuff_query
  end

  def initialize(params:, requesting_app:, repository:)
    @params         = params
    @requesting_app = requesting_app
    @repository     = repository
  end

  def standard_query
    update_content_types_in_params
    standard_opts.tap do |attrs|
      add_boilerplate_opts(attrs)
      whitelist_organizations_and_content_types(attrs)
      conditionally_update_attributes_for_organization_query(attrs)
      conditionally_update_boost_for_query(attrs)
    end
  end

  def my_stuff_query
    standard_query.tap do |attrs|
      attrs[:where]['created_by_id'] = @params[:id]
    end
  end

  def comment_query
    standard_opts.tap do |attrs|
      attrs[:where].delete(:pubdate)
      attrs[:where][:content_type] = 'comment'
      attrs[:where]['created_by_id'] = @params[:id]
    end
  end

  private

    def update_content_types_in_params
      if @params[:content_type] == 'stories'
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
        page: @params[:page].present? ? @params[:page].to_i : 1,
        per_page: @params[:per_page].present? ? @params[:per_page].to_i : 20,
        where: {
          pubdate: 5.years.ago..Time.zone.now,
          removed: {
            not: true
          }
        }
      }
    end

    def add_boilerplate_opts(attrs)
      attrs[:where][:or] = [category_options]
      attrs[:where][:published] = true if @repository.present?
    end

    def category_options
      content_types = ['news', 'market', 'talk']
      content_types << 'campaign' if @params[:organization_id].present?
      [
        {content_type: content_types},
        {content_type: 'event', "organization_id" => {not: Organization::LISTSERV_ORG_ID}}
      ]
    end

    def whitelist_organizations_and_content_types(attrs)
      if @params[:content_type].present? && @params[:content_type] == 'listserv'
        attrs[:where][:organization_id] = Organization::LISTSERV_ORG_ID
      elsif @params[:content_type].present?
        attrs[:where][:organization_id] = @requesting_app.organizations.pluck(:id) if @requesting_app.present?
        attrs[:where][:content_type] = @params[:content_type]
      else
        attrs[:where][:organization_id] = { not: Organization::LISTSERV_ORG_ID } unless listserv_org_request?
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
      if @params[:organization_id].present? || @params[:organization_id] == 'false'
        attrs[:where][:biz_feed_public] = [true, nil]
        if @params[:organization_id] == 'false'
          organization = Organization.find_by(standard_ugc_org: true)
        else
          organization = Organization.find(@params[:organization_id])
        end

        org_tagged_content_ids = organization.tagged_contents.pluck(:id)
        attrs[:where][:or] << [
          { organization_id: organization.id },
          { channel_id: organization.venue_event_ids, channel_type: 'Event' },
          { id: org_tagged_content_ids }
        ]

        attrs[:where][:or] << [
          { sunset_date: nil },
          { sunset_date: { gt: Date.current } }
        ]

        organization_show_options[@params['show']].call(attrs) if @params['show'].present?
      end
    end

    def organization_show_options
      {
        'everything' => ->(attrs) { [:pubdate, :biz_feed_public, :published].each { |k| attrs[:where].delete(k) } },
        'hidden' => ->(attrs) { attrs[:where].delete(:published); attrs[:where][:biz_feed_public] = false },
        'draft' => ->(attrs) do
          attrs[:where].delete(:published)
          attrs[:where].delete(:pubdate)
          attrs[:where][:or] << [
            { pubdate: nil },
            { pubdate: { gt: Time.current } }
          ]
        end
      }
    end

    def listserv_org_request?
      @params[:organization_id].to_i == Organization::LISTSERV_ORG_ID
    end

end