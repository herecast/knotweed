class SplitContentForAdPlacement
  def self.call(*args)
    self.new(*args).call
  end

  def initialize(content_body)
    @content_body = content_body
  end

  CHARACTER_MINIMUM = 192

  def call
    parse_content
    create_content_array
    keep_or_remove_first_node
    create_valid_position_array
    find_split_position
    return does_not_meet_requirements_split if @split_index.nil?

    create_split
    @split_content
  end

  private

  def parse_content
    @parsed_content = Nokogiri::HTML::DocumentFragment.parse(@content_body)
  end

  def does_not_meet_requirements_split
    { head: @content_body, tail: nil }
  end

  def create_content_array
    @content_array = @parsed_content.children.select do |node|
      # content rules
      node.parent == @parsed_content &&
        node.css('img').empty? &&
        node.inner_text.present?
    end
  end

  def keep_or_remove_first_node
    if @content_array.present? && @content_array[0].inner_text.length < CHARACTER_MINIMUM
      @content_array.delete_at(0)
    end
  end

  def create_valid_position_array
    @valid_position_array = @content_array.select do |node|
      node_index = @parsed_content.children.index(node)
      @content_array.include?(@parsed_content.children[node_index + 1])
    end
  end

  def find_split_position
    @split_index = @parsed_content.children.index(@valid_position_array.first)
  end

  def create_split
    head = @parsed_content.children[0..@split_index].to_html
    tail = @parsed_content.children[@split_index + 1..@parsed_content.children.length].to_html
    @split_content = { head: head, tail: tail }
  end
end
