# frozen_string_literal: true

class UgcSanitizer
  # NOTE: this needs to be kept in sync with the Ember app
  # if it changes over there.
  EMBER_SANITIZE_CONFIG = {
    elements: %w[a p ul ol li b i u br span h1
                 h2 h3 h4 h5 h6 img iframe div blockquote
                 pre],
    attributes: {
      'a' => %w[href title target],
      'img' => %w[src style class title alt],
      'div' => ['class'],
      'span' => %w[class style],
      'iframe' => %w[width height frameborder src class] # youtube
    },
    protocols: {
      'a' => { 'href' => %w[http https mailto] },
      'img' => { 'src' => ['http', 'https', :relative] }
    },
    add_attributes: {
      'a' => { 'rel' => 'nofollow' }
    },
    remove_contents: %w[style script],
    css: {
      properties: %w[
        float width padding
      ]
    }
  }.freeze

  def initialize(content)
    @raw_content = content
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    strip_empty_vertical_space(
      Sanitize.fragment(@raw_content, EMBER_SANITIZE_CONFIG)
    )
  end

  protected

  def strip_empty_vertical_space(content)
    doc = Nokogiri::HTML.fragment(content)

    # Remove empty span tags
    doc.css('span').find_all { |p| all_children_are_blank?(p) }.each(&:remove)

    # Remove empty P tags
    doc.css('p').find_all { |p| all_children_are_blank?(p) }.each(&:remove)

    # Remove multiple BR tags
    doc.css('br + br + br').each(&:remove)

    doc.to_s
  end

  def is_blank?(node)
    (node.text? && node.content.strip == '') || (node.element? && node.name == 'br')
  end

  def all_children_are_blank?(node)
    node.children.all? { |child| is_blank?(child) }
  end
end
