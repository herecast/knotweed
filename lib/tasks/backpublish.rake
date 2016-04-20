require 'time'
require 'date'

desc 'backpublish to ontonext with start date using the environment variable PUBSTARTDATE'
task :backpublish do
  @publish_job = PublishJob.new()
  start_date = ENV['PUBSTARTDATE'] ? ENV['PUBSTARTDATE'] : Date.parse(Time.now.to_s).to_s
  @publish_job.query_params = {
    :from => env['PUBSTARTDATE'],
    :published => 'both',
    :repository_id => Repository.find_by(name: 'New Ontotext').id,
    :from => start_date,
  }

  @publish_job.publish_method = 'publish_to_dsp'
  @publish_job.name = 'automated backpublish'

  # required to serialize query params?
  @publish_job.save
  @publish_job.perform
  @publish_job.destroy
end
