namespace :reporting do
  desc 'creates a content report'
  task :content_report => :environment do
    @bloggers = User.with_role(:blogger)
    root_news_cat = ContentCategory.find_by_name 'news'
    @bloggers.each do |blogger|
      my_contents = Content.joins(:publication).where(created_by: blogger, root_content_category_id: root_news_cat.id)
      my_contents.each do |content|
        old_content_reports = ContentReports.where(content_id: content.id, report_date: (Date.today-1)..Date.today)
        past_report_view = old_content_reports.max_by(&:total_view_count)
        if past_report_view
          view_count = content.view_count - past_report.total_view_count
          comment_count = content.comment_count - past_report.total_comment_count
        else
          view_count = content.view_count
        end
        
        past_report_banner = old_content_reports.max_by(&:total_banner_click_count)
        if past_report_banner
          banner_click_count = content.banner_click_count - past_report_banner.total_banner_click_count
        else
          banner_click_count = content.banner_click_count
        end

        past_report_comment = old_content_reports.max_by(&:total_comment_count)
        if past_report_comment 
          comment_count = content.comment_count = past_report_comment.total_banner_click_count
        else
          comment_count = content.comment_count
        end
          
        ContentReports.create content_id: content.id,
                              report_date: Time.zone.now,
                              view_count: view_count,
                              banner_click_count: banner_click_count,
                              comment_count: comment_count,
                              total_view_count: content.view_count,
                              total_banner_click_count: content.banner_click_count,
                              total_comment_count: content.comment_count
      end
    end

  end

end
