set :stage, :qa
set :rails_env, :production
set :deploy_to, "/var/www/knotweed-admin"
server '52.2.164.21', roles: %w{web app db}, primary: true, user: 'deploy'

set :restart_delayed_jobs, false
set :skip_sphinx_rebuild, true 
