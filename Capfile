# Load DSL and Setup Up Stages
require 'capistrano/setup'

# Includes default deployment tasks
require 'capistrano/deploy'

# Includes tasks from other gems included in your Gemfile
#
# For documentation on these, see for example:
#
#   https://github.com/capistrano/rvm
#   https://github.com/capistrano/rbenv
#   https://github.com/capistrano/chruby
#   https://github.com/capistrano/bundler
#   https://github.com/capistrano/rails
#
# require 'capistrano/rbenv'
# require 'capistrano/chruby'
require 'capistrano/bundler'
# only require rvm on the deploy task that needs it, otherwise it will run
# rvm hooks on our non-deploy tasks (eg refresh)
task :deploy do
  require 'capistrano/rvm'
end
require 'capistrano/rails/assets'
require 'capistrano/rails/migrations'
require 'thinking_sphinx/capistrano'
require "whenever/capistrano"

# Loads custom tasks from `lib/capistrano/tasks' if you have any defined.
Dir.glob('lib/capistrano/tasks/*.cap').each { |r| import r }
