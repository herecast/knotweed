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
  desc 'confirms hasActivePromotion status'
  task :confirm_has_active_promotion => :environment do
    logger = Logger.new("#{Rails.root}/log/rake_promotion_banner_#{Rails.env}.log")
    begin
      #PromotionBanner.update_all.update_active_promotions
      PromotionBanner.all.each do |promo|
        promo.update_active_promotions
      end
    rescue Exception => e
      logger.error e.message
      logger.error e.backtrace.inspect
    end
  end
end
