json.contents [@content] do |c|
  json.partial! 'api/contents/partials/content', content: c unless c.nil?
end
