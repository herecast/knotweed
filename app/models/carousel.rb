class Carousel
  attr_reader :id,
    :query,
    :organizations,
    :feed_contents,
    :carousel_type,
    :title,
    :query_params

  def initialize(**args)
    @id            = object_id
    @organizations = []
    @feed_contents = []
  end

  private

    def opts
      {
        page: 1,
        per_page: 5,
      }
    end

end