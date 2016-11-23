# config valid only for Capistrano 3.5.0
lock '3.5.0'

set :application, 'knotweed'
set :repo_url, 'git@github.com:subtextmedia/knotweed.git'

# Default branch is :master
if ENV['CI']
  set :branch, ENV['CIRCLE_BRANCH']
else
  ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }
end

set :rvm_ruby_version, '2.2.4@knotweed'

# for parsers submodule
set :git_strategy, Capistrano::Git::SubmoduleStrategy
# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, %w{config/database.yml config/application.yml config/newrelic.yml }

# Default value for linked_dirs is []
set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/assets public/exports }

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 3

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart

  desc 'Create job logging directories'
  task :create_log_record_folders do
    on roles(:web) do
      within shared_path do
        execute :mkdir, "-pv", "log/import_records"
        execute :mkdir, "-pv", "log/publish_records"
      end
    end
  end

  after :starting, :create_log_record_folders

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

  desc 'Copy robots.txt file'
  task :copy_robots_txt do
    on roles(:web), in: :parallel do
      source_file = fetch(:robots_txt_file, 'config/private_robots.txt')
      within release_path do
        execute :cp, source_file, 'public/robots.txt'
      end
    end
  end
  after :updated, :copy_robots_txt
end


namespace :sidekiq do
  desc 'Restart Sidekiq processes'
  task :restart do
    on roles(:web) do
      restart_sidekiq = fetch(:restart_sidekiq, true)
      if restart_sidekiq
        execute :sudo, :service, 'workers restart'
      end
    end
  end
end
after "deploy:published", "sidekiq:restart"
