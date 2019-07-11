echo "Running Release Tasks"

if [[ "$APP_NAME" = "Production" || "$APP_NAME" = "Staging" ]]; then 
  echo "Running Production & Staging tasks"
  echo "Running Migrations..."
  bundle exec rails db:migrate
fi

if [[ "$APP_NAME" = "Production" ]]; then
  echo "Running Production Only tasks"
  curl -d '{ "text": "<!channel> ^^ Production deploy complete", "username": "HereCats Bot", "icon_url": "https://subtext-misc.s3.amazonaws.com/mascot/cat_sunglasses.png", "attachments": [{ "title": "Meow!", "text": "https://herecast.us", "color": "2E8B57" }] }' -H "Content-Type: application/json" -X POST https://hooks.slack.com/services/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
fi