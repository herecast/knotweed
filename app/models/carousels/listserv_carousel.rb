class Carousels::ListservCarousel < Carousel

  def initialize(**args)
    super
    @location      = Location.find_by_slug_or_id(args[:location_id])
    @title         = "#{@location&.city} Community Discussion List"
    @carousel_type = 'content'
    @query_params  = { organization_id: Organization::LISTSERV_ORG_ID }
    find_contents
  end

  private

    def find_contents
      @contents = Content.search('*', opts.merge(listserv_opts))
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
              {about_location_ids: [@location&.slug]},
              {base_location_ids: [@location&.slug]}
            ]
          ]
        },
        order: {
          pubdate: 'desc'
        }
      }
    end

end
