set :stage, :qa
set :rails_env, :production
server '97.107.134.192', roles: %w{web app db}, primary: true, user: 'deploy'
set :deploy_to, "/var/www/knotweed-admin-qa"
