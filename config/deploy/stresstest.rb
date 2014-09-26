set :stage, :stresstest
set :rails_env, :production
server '97.107.134.192', roles: %w{web app db}, primary: true, user: 'deploy'
set :deploy_to, "/var/www/knotweed-admin-stresstest"

set :restart_delayed_jobs, false
