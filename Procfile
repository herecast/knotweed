web: bundle exec puma -e production -C config/puma.rb
worker: bundle exec sidekiq -i 0 -e production
release: bash ./release-tasks.sh