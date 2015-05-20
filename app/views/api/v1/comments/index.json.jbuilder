json.comments @comments do |comment|
  json.partial! 'api/v1/comments/partials/comment', comment: comment unless comment.nil?
end
