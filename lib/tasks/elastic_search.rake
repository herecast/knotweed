# frozen_string_literal: true

require 'searchkick/index'

desc 'reindex all records created_at after the given time'
task :reindex_after, [:date_string] => :environment do |_t, args|
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  date = Chronic.parse(args.date_string)

  [Content, Organization, BusinessLocation, EventInstance].each do |model|
    relation = model.where('contents.updated_at > ?', date)
    puts "Reindexing #{relation.count} #{model}'s\n"
    relation.find_each(&:reindex)
  end
end

desc 'reindex all records with pubdate > now'
task reindex_future_posts: :environment do
  relation = Content.where('pubdate > ?', Time.zone.now)
  puts "Reindexing #{relation.count} contents\n"
  Content.where('pubdate > ?', Time.zone.now).find_each(&:reindex)
end
