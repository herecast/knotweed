class GatherFeedRecords

  def self.call(*args)
    self.new(*args).call
  end

  def initialize(params:, requesting_app:, current_user:)
    @params          = params
    @requesting_app  = requesting_app
    @repository      = requesting_app.try(:repository)
    @current_user    = current_user
  end

  def call
    return empty_payload if org_present_and_biz_feed_inactive? || listserv_request_without_location?
    do_search if @params[:content_type] != 'organization'
    create_content_array
    conditionally_add_listserv_carousel
    conditionally_add_carousels
    return { records: @records, total_entries: @total_entries }
  end

  private

    def do_search
      @contents = Content.search(query, content_opts)
      @total_entries = @contents.total_entries
      assign_first_served_at_to_new_contents
    end

    def create_content_array
      if @params[:content_type] == 'organization'
        organizations = Organization.search(query, organization_opts)
        @total_entries = organizations.total_entries
        @records = organizations.map do |organization|
          FeedItem.new(organization)
        end
      else
        @records = @contents.map do |content|
          FeedItem.new(content)
        end
      end
    end

    def conditionally_add_listserv_carousel
      unless no_listserv_carousel_required?
        carousel = Carousels::ListservCarousel.new(location_id: @params[:location_id])
        if carousel.feed_contents.count > 0
          @records.insert(2, FeedItem.new(carousel))
        end
      end
    end

    def conditionally_add_carousels
      if first_page_of_standard_search_request?
        ['Publishers', 'Businesses'].each do |type|
          carousel = Carousels::OrganizationCarousel.new(title: type, query: query)
          if carousel.organizations.count > 0
            @records.insert(0, FeedItem.new(carousel))
          end
        end
      end
    end

    def content_opts
      {
        load: false,
        order: {
          latest_activity: :desc
        },
        page: @params[:page] || 1,
        per_page: per_page,
        where: {
          pubdate: 5.years.ago..Time.zone.now,
          or: [category_options],
          removed: {
            not: true
          }
        }
      }.tap do |attrs|
        attrs[:where][:published] = true if @repository.present?

        if @params[:content_type].present? && @params[:content_type] == 'listserv'
          attrs[:where][:organization_id] = Organization::LISTSERV_ORG_ID
        elsif @params[:content_type].present?
          attrs[:where][:organization_id] = @requesting_app.organizations.pluck(:id) if @requesting_app.present?
          attrs[:where][:content_type] = @params[:content_type]
        else
          attrs[:where][:organization_id] = { not: Organization::LISTSERV_ORG_ID } unless listserv_org_request?
        end


        if my_stuff_request?
          attrs[:where]['created_by.id'] = @current_user.id
        elsif @params[:location_id].present?
          location = Location.find_by_slug_or_id @params[:location_id]

          if @params[:radius].present? && @params[:radius].to_i > 0
            locations_within_radius = Location.non_region.within_radius_of(location, @params[:radius].to_i).map(&:id)

            attrs[:where][:or] << [
              {my_town_only: false, all_loc_ids: locations_within_radius},
              {my_town_only: true, all_loc_ids: location.id}
            ]
          else
            attrs[:where][:or] << [
              {about_location_ids: [location.id]},
              {base_location_ids: [location.id]}
            ]
          end
        end

        if @params[:organization_id].present?
          attrs[:where][:biz_feed_public] = [true, nil]

          organization = Organization.find(@params[:organization_id])

          org_tagged_content_ids = organization.tagged_contents.pluck(:id)
          attrs[:where][:or] << [
            { organization_id: organization.id },
            { channel_id: organization.venue_event_ids, channel_type: 'Event' },
            { id: org_tagged_content_ids }
          ]

          attrs[:where][:or] << [
            { sunset_date: nil },
            { sunset_date: { lt: Date.current } }
          ]

          organization_show_options[@params['show']].call(attrs) if @params['show'].present?
        end

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
    end

    def category_options
      content_types = ['news', 'market', 'talk']
      content_types << 'campaign' if @params[:organization_id].present?
      [
        {content_type: content_types},
        {content_type: 'event', "organization.name" => {not: 'Listserv'}}
      ]
    end

    def organization_show_options
      {
        'everything' => ->(attrs) { [:pubdate, :biz_feed_public, :published].each { |k| attrs[:where].delete(k) } },
        'hidden' => ->(attrs) { attrs.delete(:published); attrs[:where][:biz_feed_public] = false },
        'draft' => ->(attrs) { attrs.delete(:published); attrs[:where][:pubdate] = nil }
      }
    end

    def organization_opts
      {
        page: page,
        per_page: per_page,
        where: {
          org_type: ['Blog', 'Publisher', 'Publication', 'Business']
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

    def listserv_request_without_location?
      listserv_org_request? && @params[:location_id].blank?
    end

    def first_page_of_standard_search_request?
      @params[:query].present? &&
        @params[:content_type] != 'organization' &&
        @params[:organization_id].blank? &&
        page == 1
    end

    def no_listserv_carousel_required?
      @params[:content_type].present? ||
        @params[:query].present? ||
        @params[:organization_id].present? ||
        my_stuff_request? ||
        page > 1
    end

    def listserv_org_request?
      @params[:organization_id].to_i == Organization::LISTSERV_ORG_ID
    end

    def my_stuff_request?
      ['me', 'my_stuff', 'mystuff'].include?(@params[:radius].to_s.downcase)
    end

    def assign_first_served_at_to_new_contents
      BackgroundJob.perform_later('AlertProductTeamOfNewContent', 'call',
        content_ids: @contents.map(&:id),
        current_time: Time.current.to_s
      )
    end

end