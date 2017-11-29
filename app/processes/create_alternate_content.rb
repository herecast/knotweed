class CreateAlternateContent

  ALTERNATE_IMAGE_URL = 'https://s3.amazonaws.com/knotweed/duv/Default_Photo_News-01-1.jpg'

  def self.call(*args)
    self.new(*args).call
  end

  def initialize(original_content)
    @original_content = original_content
  end

  def call
    return content_dupe
  end

  private

    def content_dupe
      image = Image.new(id: 1)
      image.define_singleton_method(:image) { Hashie::Mash.new({url: ALTERNATE_IMAGE_URL}) }
      image.define_singleton_method(:image_url) { ALTERNATE_IMAGE_URL }
      dupe = Content.new(alternate_content_attributes)
      dupe.define_singleton_method(:images) { [image] }
      dupe
    end

    def content_category
      ContentCategory.find_or_create_by(name: 'alternate_content')
    end

    def alternate_content_attributes
      {
        title: "We're sorry!",
        raw_content: "This post is not available at the present time. We apologize for the inconvenience. Please email dailyuv@subtext.org with any questions!",
        authors: 'The team at DailyUV',
        organization_id: 793,
        content_category_id: content_category.id,
        root_content_category_id: content_category.id,
        content_type: @original_content.content_type,
        id: @original_content.id,
        pubdate: @original_content.pubdate
      }
    end

end