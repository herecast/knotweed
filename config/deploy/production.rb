set :rails_env, 'production'
set :deploy_to, "/var/www/knotweed-admin"
server '52.3.25.99', roles: %w{web app db}, primary: true, user: 'deploy'

set :restart_delayed_jobs, true
set :robots_file, 'config/public_robots.txt'
