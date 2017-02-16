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
    return does_not_meet_requirements_split unless greater_than_minimum_length?
    create_paragraph_array
    find_first_p_node
    find_split_position
    return does_not_meet_requirements_split unless @index_of_first_p.present?
    create_split
    @split_content
  end

  private

    def parse_content
      @parsed_content = Nokogiri::HTML::DocumentFragment.parse(@content_body)
    end

    def greater_than_minimum_length?
      @parsed_content.inner_text.length > 255
    end

    def does_not_meet_requirements_split
      { head: @content_body, tail: nil }
    end

    def create_paragraph_array
      @paragraph_array = @parsed_content.css('p').select { |n| n.inner_text.length > 0 }
    end

    def find_first_p_node
      if @paragraph_array[0].inner_text.length >= CHARACTER_MINIMUM
        @first_p_node = @paragraph_array[0]
      else
        @first_p_node = @paragraph_array[1]
      end
    end

    def find_split_position
      @index_of_first_p = @parsed_content.children.index(@first_p_node)
      ensure_next_node_is_not_empty_or_image
    end

    def find_next_p_node
      next_p = @parsed_content.css('p')[@index_of_first_p + 1]
      if next_p.try(:parent) == @parsed_content && next_p.children.css('img').empty?
        @index_of_first_p = @parsed_content.children.index(next_p)
      elsif next_p.present?
        @index_of_first_p += 1
        find_next_p_node
      else
        @index_of_first_p = nil
      end
    end

    def img_or_empty_p_is_next_node?
      if @index_of_first_p.present?
        node = @parsed_content.children[@index_of_first_p + 1]
        node.present? && (node.children.css('img').present? || node.inner_text.empty?)
      else
        false
      end
    end

    def ensure_next_node_is_not_empty_or_image
      while img_or_empty_p_is_next_node?
        find_next_p_node
      end
    end

    def create_split
      head = @parsed_content.children[0..@index_of_first_p].to_html
      tail = @parsed_content.children[@index_of_first_p + 1..@parsed_content.children.length].to_html
      @split_content = { head: head, tail: tail }
    end

end