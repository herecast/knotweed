class FeedItem
  attr_reader :model_type,
              :id,
              :content,
              :carousel,
              :organization

  def initialize(object)
    @id = object.id
    set_model_type(object)
  end

  private

  def set_model_type(object)
    if object.class.to_s.include?('Carousel')
      @model_type = 'carousel'
      @carousel = object
    elsif [Hashie::Mash, Searchkick::HashWrapper].include?(object.class)
      @model_type = 'content'
      @content = object
    elsif object.class == Organization
      @model_type = 'organization'
      @organization = object
    end
  end
  end
