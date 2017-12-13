class FeedItem
  attr_reader :model_type,
    :id,
    :feed_content,
    :carousel,
    :organization

  alias :read_attribute_for_serialization :send

  def initialize(model_type:, id:, **opts)
    @model_type   = model_type
    @id           = id
    @feed_content = opts[:feed_content]
    @carousel     = opts[:carousel]
    @organization = opts[:organization]
  end
end