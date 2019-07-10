# frozen_string_literal: true

class CreateAlternateContent
  ALTERNATE_IMAGE_URL = 'https://s3.amazonaws.com/knotweed/duv/Default_Photo_News-01-1.jpg'
  ALTERNATE_TITLE = "We're sorry!"
  ALTERNATE_TEXT = 'This post is not available at the present time. We apologize for the inconvenience. Please email help@herecast.us with any questions!'
  ALTERNATE_AUTHORS = 'The team at HereCast'
  ALTERNATE_ORGANIZATION_ID = 793

  def self.call(*args)
    new(*args).call
  end

  def initialize(original_content)
    @original_content = original_content
  end

  def call
    content_dupe.call(@original_content, alternate_content_attributes)
  end

  private

  def content_dupe
    proc do |content, attrs|
      alt_image_url = content.alternate_image_url.presence || ALTERNATE_IMAGE_URL
      image = Image.new(id: 1, primary: true)
      image.define_singleton_method(:image) { Hashie::Mash.new(url: alt_image_url) }
      image.define_singleton_method(:image_url) { alt_image_url }
      dupe = Content.new(attrs)
      dupe.define_singleton_method(:images) { [image] }
      dupe
    end
  end

  def content_category
    ContentCategory.find_or_create_by(name: 'alternate_content')
  end

  def alternate_content_attributes
    {
      title: @original_content.alternate_title.presence || ALTERNATE_TITLE,
      raw_content: @original_content.alternate_text.presence || ALTERNATE_TEXT,
      authors: @original_content.alternate_authors.presence || ALTERNATE_AUTHORS,
      organization_id: @original_content.alternate_organization_id.presence || ALTERNATE_ORGANIZATION_ID,
      content_category_id: content_category.id,
      root_content_category_id: content_category.id,
      content_type: @original_content.content_type,
      id: @original_content.id,
      pubdate: @original_content.pubdate
    }
  end
end
