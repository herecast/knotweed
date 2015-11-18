require './lib/capistrano/submodule_strategy'
# config valid only for Capistrano 3.1
lock '3.1.0'

set :application, 'knotweed'
set :repo_url, 'git@github.com:subtextmedia/knotweed.git'

# Default branch is :master
ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

set :rvm_ruby_version, '1.9.3-p545@knotweed'

set :delayed_job_args, "-n 4"

# for parsers submodule
set :git_strategy, SubmoduleStrategy
# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, %w{config/database.yml config/application.yml config/production.sphinx.conf config/thinking_sphinx.yml}

# Default value for linked_dirs is []
set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/assets public/exports binlog db/sphinx}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 3

# Hack for a bug in Thinking Sphinx, will be fixed with next release
# (https://github.com/pat/thinking-sphinx/issues/787)
set :thinking_sphinx_rails_env, fetch(:rails_env, 'production')
set :whenever_roles, [:web, :db]

namespace :deploy do

  desc 'Restart application'
  task :restart do
    restart_delayed_jobs = fetch(:restart_delayed_jobs, true)
    invoke 'delayed_job:restart' if restart_delayed_jobs
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart

  task :reconfigure_sphinx do
    invoke 'thinking_sphinx:configure'
  end

  after :publishing, :reconfigure_sphinx

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
