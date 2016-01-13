namespace :backpopulate do
  task :latest_comment_pubdates => :environment do
    puts "Updating #{Content.where(channel_type: 'Comment', parent_id: nil).count} parent records"
    Content.where(channel_type: 'Comment').where('parent_id is not null').order('pubdate DESC').each do |c|
      parent = c.find_root_parent
      if parent.latest_comment_pubdate.blank? or c.pubdate > parent.latest_comment_pubdate
        parent.update_attribute :latest_comment_pubdate, c.pubdate
      end
    end
  end

  task :root_parent_ids => :environment do
    puts 'Updating all Content records where parent_id: nil and root_parent_id: nil'
    # to make this more efficient, we're updating all root parents first
    # with a single SQL query, then cycling through the remaining ones. 
    # In other words, this handles more than 300,000 records, allowing the next
    # part to only iterate through a few thousand.
    Content.where(root_parent_id: nil, parent_id: nil).update_all('root_parent_id = id')
    puts "Updating child contents, #{Content.where(root_parent_id: nil).count}"
    Content.where(root_parent_id: nil).each do |c|
      c.update_column :root_parent_id, c.find_root_parent.id
    end
  end
end
