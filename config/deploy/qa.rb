set :stage, :qa
set :rails_env, :production
set :rvm_roles, [:web, :app]
set :deploy_to, "/var/www/knotweed-admin"
server '52.2.164.21', roles: %w{web app db}, primary: true, user: 'deploy'
server 'test-dsp.subtext.org', roles: %w{source_dsp}, primary: false, user: 'dsp'
server 'dev-dsp.subtext.org', roles: %w{dest_dsp}, primary: false, user: 'dsp'

set :restart_delayed_jobs, true
