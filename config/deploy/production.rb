set :rails_env, 'production'
set :deploy_to, "/var/www/knotweed-admin"
server 'admin.subtext.org', roles: %w{web app db}, primary: true, user: 'deploy'

set :restart_delayed_jobs, true
set :restart_sidekiq, true
set :robots_file, 'config/public_robots.txt'
