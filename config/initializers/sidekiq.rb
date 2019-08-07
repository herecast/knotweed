# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq/web'
require 'sidekiq-scheduler'
require 'sidekiq-scheduler/web'

Sidekiq::Web.set :session_secret, Rails.application.secrets[:secret_token]
Sidekiq::Web.set :sessions, key: '_knotweed_sidekiq'

if Rails.env.production? && Figaro.env.app_name == 'Production'
  Sidekiq.configure_server do |config|
    config.on(:startup) do
      Sidekiq.schedule = YAML.load_file(File.expand_path('../../config/job_schedule.yml', __dir__))
      Sidekiq::Scheduler.reload_schedule!
    end
  end
end

Sidekiq.default_worker_options = {
  unique: :until_and_while_executing,
  unique_args: ->(args) { args.first.except('job_id') }
}
