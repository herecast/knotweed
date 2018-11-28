Knotweed
========================

Local Development w/ Docker
-------------------------------
1. Clone this repo -> navigate terminal to knotweed root directory
2. Install Docker on your machine. You can [get started here](https://www.docker.com/get-started)
3. Run `cp docker-compose.yml.example docker-compose.yml`
4. Run `mv /knotweed/config/database.yml.docker /knotweed/config/database.yml` -- note that this will overwrite your database config if you have an existing local app
5. Run `docker-compose up` -- the first time you do this, it will take a while
6. In separate terminal window, run `docker-compose run --rm web bundle exec rake db:create db:schema:load db:seed`

By default, the server will run on port 3000 -- you can change this in docker-compose.yml. Docker will run elasticsearch, redis and postgres alongside the API.

Deployment with Heroku
--------------------------
You must be associated with a Heroku account.

Get the heroku remote address, add it as a remote (in this example, the remote is `heroku`)

Deployment is as easy as `git push heroku`

Note: if you need to push a non-master branch, you must use `git push heroku <branch name>:master` as in `git push heroku heroku:master`

The Knotweed app relies on reddis, which can be added through Heroku console

In Heroku, ENV["DATABASE_URL"] must be set: this can be a remote DB (and username/password must be set) or a Postgres instance in Heroku

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
