class UgcSanitizer
  # NOTE: this needs to be kept in sync with the Ember app
  # if it changes over there.
  EMBER_SANITIZE_CONFIG = {
    elements: ['a', 'p', 'ul', 'ol', 'li', 'b', 'i', 'u', 'br', 'span', 'h1',
               'h2', 'h3', 'h4', 'h5', 'h6', 'img', 'iframe','div', 'blockquote',
               'pre'],
    attributes: {
      'a' => ['href', 'title', 'target'],
      'img' => ['src', 'style', 'class', 'title', 'alt'],
      'div' => ['class'],
      'span' => ['class','style'],
      'iframe' => ['width', 'height', 'frameborder', 'src', 'class'] # youtube
    },
    protocols: {
      'a' => { 'href' => ['http', 'https', 'mailto'] }
    },
    add_attributes: {
      'a' => { 'rel' => 'nofollow' }
    },
    css: {
      properties: [
        'float', 'width', 'padding'
      ]
    }
  }

  def initialize(content)
    @raw_content = content
  end

  def self.call(*args)
    self.new(*args).call
  end

  def call
    Sanitize.fragment(@raw_content, EMBER_SANITIZE_CONFIG)
  end

end
