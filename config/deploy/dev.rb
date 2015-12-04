set :rails_env, 'production'
set :deploy_to, "/var/www/knotweed-admin"
server 'dev.subtext.org', roles: %w{web app db}, primary: true, user: 'deploy'

set :restart_delayed_jobs, false
