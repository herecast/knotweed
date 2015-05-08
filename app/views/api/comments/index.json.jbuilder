json.comments @comments do |comment|
  json.partial! 'api/comments/partials/comment', comment: comment unless comment.nil?
end
