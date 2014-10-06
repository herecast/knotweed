set :stage, :abtest
set :rails_env, 'production'
set :deploy_to, "/var/www/knotweed-admin"
server '173.255.231.20', roles: %w{web app db}, primary: true, user: 'deploy'

set :restart_delayed_jobs, false
