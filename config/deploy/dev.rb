set :rails_env, 'production'
set :deploy_to, "/var/www/knotweed-admin"
set :rvm_roles, [:web, :app]
server 'dev.subtext.org', roles: %w{web app db}, primary: true, user: 'deploy'
server 'test-dsp.subtext.org', roles: %w{source_dsp}, primary: false, user: 'dsp'
server 'dev-dsp.subtext.org', roles: %w{dest_dsp}, primary: false, user: 'dsp'

set :restart_delayed_jobs, false
