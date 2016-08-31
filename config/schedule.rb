# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

# Report table population & banner daily count reset

every 1.day, at: '11:55 pm' do
  rake 'reporting:create_content_report'
  rake 'reporting:create_promotion_banner_report'
end

# banner daily count reset and confirm has_active_promo status
every 1.day, at: '12:01 am' do
  rake 'promotion_banner:reset_daily_impression_count'
  rake 'promotion_banner:confirm_has_active_promotion'
end
