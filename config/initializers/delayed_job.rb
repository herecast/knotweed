Delayed::Worker.backend = :active_record
Delayed::Worker.max_attempts = 1
Delayed::Worker.max_run_time = 1.month
# Delayed::Worker.delay_jobs = !Rails.env.test?
