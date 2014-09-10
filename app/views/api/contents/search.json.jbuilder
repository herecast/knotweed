json.contents @contents do |c|
  json.id c.id
  json.content fix_ts_excerpt(c.excerpts.content)
  json.title fix_ts_excerpt(c.excerpts.title)
  json.score c.weight
end
