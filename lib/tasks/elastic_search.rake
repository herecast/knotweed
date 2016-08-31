desc 'reindex all records created_at after the given time'
task :reindex_after, [:date_string] => :environment do |t, args|
  date = Chronic.parse(args.date_string)

  [Content, BusinessLocation, Organization, BusinessProfile, EventInstance].each do |model|
    relation = model.where('updated_at > ?', date) 
    puts "Reindexing #{relation.count} #{model.to_s}'s\n"
    relation.find_each do |c|
      c.reindex
    end
  end

end
