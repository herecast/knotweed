Knotweed
========================

Logging
--------------------------
Log files are shared between 'releases' so they should be continuous across multiple deployments. If you need to access them, they're in

    /home/deploy/knotweed/current/log

delayed_job.log is a simple file that shows output from running jobs -- mostly just "job id is running," "job finished," that sort of thing.

More specific logging for imports and publishing is found in log/import_records and log/publish_records respectively. You should be able to read those files from any user account.

Development
=========================

Necessary resources
--------------------------
Postgres: `brew install postgresql` and `brew services start postgresql`

Redis: `brew install redis` and `brew services start redis`

Elasticsearch: `brew install elasticsearch@2.4` and `brew services start elasticsearch`

Note: we are currently pinned to ES version 2.4

For Sidekiq: `bundle install` and `sidekiq -C config/sidekiq.yml -e development`

Using Zeus Standalone
--------------------------
Zeus (https://github.com/burke/zeus) is a gem that preloads your rails application to make running specs, console, and other commands quicker. The gem recommends that you not include it in your Gemfile because it's much faster if it's not run via bundler. Each developer is responsible for installing and using zeus on their own.

    gem install zeus

To use zeus, simply run `zeus start` from your application directory. That will give you a list of commands you can run, but the short and sweet of it is that `zeus console` will spin up a Rails console almost instantly and `zeus test` or `zeus test spec/models/model_spec.rb` will run your specs.

Using Guard
-------------------------------
Guard will watch your code as you make changes to it, and run any rspec files that match what you're working on after you save the file. (https://github.com/guard/guard) It helps keep the test feedback loop short because you don't have to manually trigger your test.

To have guard automatically watch changes, simple run the following command in another terminal window:

    bundle exec guard

The App has both Guard and Zeus in the Gemfile, and they're setup to work together.  Guard will automatically start/stop Zeus as needed. No separate Zeus install or commands are needed.
