# frozen_string_literal: true

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
    @organizations = Organization.search(@query, opts.merge(contributor_opts))
  end

  def contributor_opts
    {
      where: {
        can_publish_news: true,
        archived: { in: [false, nil] }
      }
    }
  end
end
