namespace :promotion_banner do
  desc 'resets daily_impression_count to 0'
  task :reset_daily_impression_count => :environment do
    logger = Logger.new("#{Rails.root}/log/rake_promotion_banner_#{Rails.env}.log")
    begin
      PromotionBanner.where("daily_impression_count > 0").update_all("daily_impression_count = 0")
    rescue Exception => e
      logger.error e.message
      logger.error e.backtrace.inspect
    end
  end
end
