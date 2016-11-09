class ReportingJob < ApplicationJob

  # note -- the reporting depends on happening before the reset of the daily impression count.
  # We don't need to rush through these jobs, so we can just run them all inline to ensure
  # the correct order.
  def perform
    Knotweed::Application.load_tasks
    Rake::Task['reporting:create_content_report'].invoke
    Rake::Task['reporting:create_promotion_banner_report'].invoke
    Rake::Task['promotion_banner:reset_daily_impression_count'].invoke
    Rake::Task['promotion_banner::confirm_has_active_promotion'].invoke
  end

end
