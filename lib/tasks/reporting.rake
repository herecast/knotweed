namespace :reporting do
  desc 'creates a content report'
  task :create_content_report => :environment do
    logger = Logger.new("#{Rails.root}/log/rake_content_report_#{Rails.env}.log")
    begin
      @bloggers = User.with_role(:blogger)
      root_news_cat = ContentCategory.find_by_name 'news'
      @bloggers.each do |blogger|
        my_contents = Content.joins(:organization).where(created_by: blogger, root_content_category_id: root_news_cat.id)
        my_contents.each do |content|
          old_content_report = ContentReport.where(content_id: content.id).order(:id).last

          if old_content_report
            view_count = content.view_count - old_content_report.total_view_count
            banner_click_count = content.banner_click_count - old_content_report.total_banner_click_count
            comment_count = content.comment_count - old_content_report.total_comment_count
          else
            view_count = content.view_count
            banner_click_count = content.banner_click_count
            comment_count = content.comment_count
          end

          ContentReport.create! content_id: content.id,
                                report_date: Time.now,
                                view_count: view_count,
                                banner_click_count: banner_click_count,
                                comment_count: comment_count,
                                total_view_count: content.view_count,
                                total_banner_click_count: content.banner_click_count,
                                total_comment_count: content.comment_count
        end
      end
    rescue Exception => e
      logger.error e.message
      logger.error e.backtrace.inspect
    end

  end

  desc 'create a promotion banner report'
  task :create_promotion_banner_report => :environment do
    logger = Logger.new("#{Rails.root}/log/rake_promotion_banner_report_#{Rails.env}.log")
    begin
      @active_promos = PromotionBanner.where("? >= campaign_start AND ? <= campaign_end", Date.today, Date.today)
      @active_promos.each do |promotion_banner|
        old_promotion_report = PromotionBannerReport.where(promotion_banner_id: promotion_banner.id).order(:id).last

        if old_promotion_report
          impression_count = promotion_banner.impression_count - old_promotion_report.total_impression_count
          click_count = promotion_banner.click_count - old_promotion_report.total_click_count
        else
          impression_count = promotion_banner.impression_count
          click_count = promotion_banner.click_count
        end

        PromotionBannerReport.create! promotion_banner_id: promotion_banner.id,
                                       report_date: Time.now,
                                       impression_count: impression_count,
                                       click_count: click_count,
                                       total_impression_count: promotion_banner.impression_count,
                                       total_click_count: promotion_banner.click_count
      end
    rescue Exception => e
      logger.error e.message
      logger.error e.backtrace.inspect
    end

  end
end
