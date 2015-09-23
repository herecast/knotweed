set :stage, :staging
set :rails_env, 'production'
set :deploy_to, "/var/www/knotweed-admin"
server 'stage-web.subtext.org', roles: %w{web app db}, primary: true, user: 'deploy'

set :restart_delayed_jobs, true
set :skip_sphinx_rebuild, true
