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
end
