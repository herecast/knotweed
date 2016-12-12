namespace :promotion_banner do
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
