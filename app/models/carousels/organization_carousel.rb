class Carousels::OrganizationCarousel < Carousel

  def initialize(**args)
    super
    @carousel_type = 'organization'
    @title         = args[:title]
    @query         = args[:query]
    find_organizations
  end

  private

    def find_organizations
      @organizations = Organization.search(@query, opts.merge(send("#{@title.downcase}_opts")))
    end

    def publishers_opts
      {
        where: {
          org_type: ['Blog', 'Publisher', 'Publication']
        }
      }
    end

    def businesses_opts
      {
        where: {
          org_type: 'Business'
        },
        boost_where: {
          biz_feed_active: true
        }
      }
    end

end