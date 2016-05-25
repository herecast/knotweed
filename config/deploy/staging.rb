set :stage, :staging
set :rails_env, 'production'
set :rvm_roles, [:web, :app]
set :deploy_to, "/var/www/knotweed-admin"
set :source_mysql_host, 'reports.subtext.org'
set :dest_mysql_host, 'stage-004.cogj3v9uqpkv.us-east-1.rds.amazonaws.com'
set :source_mysql_database, 'admin_prod'
set :dest_mysql_database, 'admin_prod'
set :dsp_endpoint_hostname, 'stage-dsp.subtext.org'
set :site_endpoint, 'http://stage-consumer.subtext.org'
server '52.70.81.201', roles: %w{web app db}, primary: true, user: 'deploy'
server 'test-dsp.subtext.org', roles: %w{source_dsp}, primary: false, user: 'dsp', no_release: true
server 'stage-dsp.subtext.org', roles: %w{dest_dsp}, primary: false, user: 'dsp', no_release: true

set :restart_delayed_jobs, true
