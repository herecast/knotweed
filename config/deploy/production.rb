set :stage, :staging
set :rails_env, 'production'
set :deploy_to, "/var/www/knotweed-admin"
server '23.92.16.168', roles: %w{web app db}, primary: true, user: 'deploy'

set :restart_delayed_jobs, true
