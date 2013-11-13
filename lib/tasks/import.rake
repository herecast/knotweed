namespace :import do

  # creates import jobs to import all VN RSS days
  # from november 13, 2012 till now
  task :vn_rss_backdated_imports => :environment do

    organization = Organization.find_or_create_by_name("The Valley News")
    begin 
      parser = Parser.find_by_filename("valley_news_rss_parser.rb")
    rescue ActiveRecord::RecordNotFound
      puts "VN RSS parser not found"
      break
    end
    source_path = "http://www.vnews.com/csp/mediapool/sites/Shared/assets/csp/helper/newsbankXML.csp?pubname=ValleyNews"

    date = Date.parse("2012-11-13")
    while date < Date.today
      rss_ij = ImportJob.new({ name: "Rake VN Import (RSS) #{date.strftime("%Y%m%d")}" })
      rss_ij.organization = organization
      rss_ij.parser = parser
      rss_ij.source_path = source_path + "&pubdate=#{date.strftime("%Y%m%d")}"
      rss_ij.save!
      rss_ij.enqueue_job
      date = date + 1.day
    end

  end

end
