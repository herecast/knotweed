set :stage, :staging
set :rails_env, 'production'
set :deploy_to, "/var/www/knotweed-admin"
server '52.70.81.201', roles: %w{web app db}, primary: true, user: 'deploy'
server 'test-dsp.subtext.org', roles: %w{source_dsp}, primary: false, user: 'dsp'
server 'stage-dsp.subtext.org', roles: %w{dest_dsp}, primary: false, user: 'dsp'

set :restart_delayed_jobs, true
