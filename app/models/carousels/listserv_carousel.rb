class Carousels::ListservCarousel < Carousel

  def initialize(**args)
    super
    @location      = Location.find_by_slug_or_id(args[:location_id])
    @title         = "#{@location&.city} Community Discussion List"
    @carousel_type = 'feed_content'
    @query_params  = { organization_id: Organization::LISTSERV_ORG_ID }
    find_feed_contents
  end

  private

    def find_feed_contents
      @feed_contents = Content.search('*', opts.merge(listserv_opts))
    end

    def listserv_opts
      {
        load: false,
        where: {
          organization_id: Organization::LISTSERV_ORG_ID,
          removed: {
            not: true
          },
          or: [
            [
              {about_location_ids: [@location&.id]},
              {base_location_ids: [@location&.id]}
            ]
          ]
        },
        order: {
          pubdate: 'desc'
        }
      }
    end

end