# frozen_string_literal: true

module CommentsHelper
  def sanitize_comment_content(content)
    content.gsub('<p>', '').gsub('</p>', '').gsub('<br />', '')
  end
end
