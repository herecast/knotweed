set :stage, :qa
set :rails_env, :production
set :rvm_roles, [:web, :app]
set :deploy_to, "/var/www/knotweed-admin"
set :source_database_host, 'reports.subtext.org'
set :dest_database_host, 'qa-005.cogj3v9uqpkv.us-east-1.rds.amazonaws.com'
set :source_database, 'knotweed'
set :dest_database, 'knotweed'
set :dsp_endpoint_hostname, 'dev-dsp.subtext.org'
set :site_endpoint, 'http://qa-consumer.subtext.org'
set :source_es_url, 'https://search-prod-000-phtppggkgrtbom2xy5o2eanpt4.us-east-1.es.amazonaws.com'
set :dest_es_url, 'https://search-qa-000-4ughrvq442becl47nyw6uvn3xm.us-east-1.es.amazonaws.com'
set :es_repository, 'subtext-es-snapshots'
server 'qa-web.subtext.org', roles: %w{web app db}, primary: true, user: 'deploy'
server 'test-dsp.subtext.org', roles: %w{source_dsp}, primary: false, user: 'dsp', no_release: true
server 'dev-dsp.subtext.org', roles: %w{dest_dsp}, primary: false, user: 'dsp', no_release: true

set :restart_sidekiq, true
