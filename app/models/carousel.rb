class Carousel
  attr_reader :id,
    :query,
    :organizations,
    :carousel_type,
    :title

  alias :read_attribute_for_serialization :send

  def initialize(organization_type:, query:)
    @title         = organization_type
    @carousel_type = 'organization'
    @query         = query
    @id            = object_id
    find_organizations
  end

  private

    def find_organizations
      @organizations = Organization.search(@query, opts.merge(send("#{@title.downcase}_opts")))
    end

    def opts
      {
        page: 1,
        per_page: 5,
      }
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