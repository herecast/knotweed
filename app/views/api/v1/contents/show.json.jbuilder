json.contents [@content] do |c|
  json.partial! 'api/v1/contents/partials/content', content: c unless c.nil?
end
