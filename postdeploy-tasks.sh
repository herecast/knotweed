echo "Running Post-deploy tasks"

if ! [[ "$APP_NAME" = "Production" || "$APP_NAME" = "Staging" ]]; then
  echo "Running Review App tasks"
  echo "DB setup & Elasticsearch indexing..."
  bundle exec rake db:schema:load db:migrate indexing:build_indexes db:seed
fi