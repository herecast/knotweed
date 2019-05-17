echo "Running Release Tasks"

if [[ "$APP_NAME" = "Production" || "$APP_NAME" = "Staging" ]]; then 
  echo "Running Production & Staging tasks"
  echo "Running Migrations..."
  bundle exec rails db:migrate
fi