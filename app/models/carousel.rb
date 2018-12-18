# frozen_string_literal: true

class Carousel
  attr_reader :id,
              :query,
              :organizations,
              :contents,
              :carousel_type,
              :title,
              :query_params

  def initialize(**_args)
    @id            = object_id
    @organizations = []
    @contents = []
  end

  private

  def opts
    {
      page: 1,
      per_page: 5
    }
  end
end
