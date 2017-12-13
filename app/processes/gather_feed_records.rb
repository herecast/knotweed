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
    do_search if @params[:content_type] != 'organization'
    create_content_array
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
          FeedItem.new(
            model_type: 'organization',
            id: organization.id,
            organization: organization
          )
        end
      else
        @records = @contents.map do |content|
          FeedItem.new(
            model_type: 'feed_content',
            id: content.id,
            feed_content: content
          )
        end
      end
    end

    def conditionally_add_carousels
      if @params[:query].present? && @params[:content_type] != 'organization' && @params[:organization_id].blank?
        ['Publishers', 'Businesses'].each do |type|
          carousel = Carousel.new(organization_type: type, query: query)
          if carousel.organizations.count > 0
            @records.insert(0,
              FeedItem.new(
                model_type: 'carousel',
                id: carousel.id,
                carousel: carousel
              )
            )
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
        attrs[:where][:content_type] = @params[:content_type] if @params[:content_type].present?
        attrs[:where][:organization_id] = @requesting_app.organizations.pluck(:id) if @requesting_app.present?

        if ['me', 'my_stuff', 'mystuff'].include?(@params[:radius].to_s.downcase)
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
        page: @params[:page] || 1,
        per_page: @params[:per_page] || 20,
        where: {
          org_type: ['Blog', 'Publisher', 'Publication', 'Business']
        }
      }
    end

    def per_page
      @params[:per_page] || 20
    end

    def query
      @params[:query].present? ? @params[:query] : '*'
    end

    def assign_first_served_at_to_new_contents
      BackgroundJob.perform_later('AssignFirstServedAtToNewContent', 'call',
        content_ids: @contents.map(&:id),
        current_time: Time.current.to_s
      )
    end

end