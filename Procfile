web: bundle exec puma -e production -C config/puma.rb
worker: bundle exec sidekiq -i 0 -e production
release: bundle exec rake db:migrate