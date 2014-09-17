json.page @page unless @page.nil?
json.total_pages @pages unless @pages.nil?
json.contents @contents do |c|
  json.partial! 'api/contents/partials/content', content: c
end
