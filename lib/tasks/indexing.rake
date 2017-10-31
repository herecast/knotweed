namespace :indexing do
  task :rebuild_content_index => :environment do
    Content.reindex import: false
    Content.where('organization_id NOT IN (4,5,328)')\
      .where(published: true)\
      .where('root_content_category_id > 0')\
      .where('created_at >= ?', 3.months.ago)\
      .order('pubdate DESC')\
      .each(&:reindex_async)
    puts "Operation completed"
  end

  task :full_reindex_content => :environment do
    index_name = Content.reindex(async: {wait: true}, refresh_interval: "30s")
    puts "Reindexing last hour"
    Content.search_import.where('contents.updated_at > ?', 2.hours.ago).each(&:reindex_async)
    puts "Operation completed"
  end
end
