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

every 1.day, at: '11:50 pm' do
  rake 'reporting:create_content_report'
  rake 'reporting:create_promotion_banner_report'
end

# Sphinx Indexing

job_type :sphinx_script, "cd :path && ./lib/indexing/:task"

every '1-59 * * * *' do
  sphinx_script "delta_index.sh"
end

every '0 1-23 * * *' do
  sphinx_script "merge_deltas.sh"
end

every '0 0 * * *' do
  sphinx_script "full_index.sh"
end
