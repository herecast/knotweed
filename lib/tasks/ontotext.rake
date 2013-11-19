namespace :ontotext do

  task :export_failed_posts => :environment do
    
    failed_ids = []
    File.open("#{Rails.root}/log/publishing.log", "r") do |f|
      f.each_line do |line|
        matched_id = /\d{4,}/.match(line)
        failed_ids << matched_id[0].to_i if matched_id
      end
    end

    failed_ids.each do |id|
      begin
        c = Content.find(id)
        if c.published == false
          c.export_to_xml
        end
      rescue ActiveRecord::RecordNotFound
        puts "#{id} not found"
      end
    end

  end
end
