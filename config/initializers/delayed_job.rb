Delayed::Worker.backend = :active_record
Delayed::Worker.max_attempts = 5
Delayed::Worker.max_run_time = 1.month
Delayed::Worker.logger = Logger.new(File.join(Rails.root, 'log', 'delayed_job.log'), 10, 100*1024*1024)
# Delayed::Worker.delay_jobs = !Rails.env.test?
