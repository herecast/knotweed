set :stage, :qa
set :rails_env, :production
set :deploy_to, "/var/www/knotweed-admin-qa"
server '97.107.134.192', roles: %w{web app db}, primary: true, user: 'deploy'

set :restart_delayed_jobs, false
set :skip_sphinx_rebuild, false 
