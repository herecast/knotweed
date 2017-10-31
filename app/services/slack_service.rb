module SlackService
  extend self

  BOTS = {
    chaco: {
      username: 'Chaco Bot',
      icon_url: 'https://s3.amazonaws.com/subtext-misc/mascot/chaco.jpg'
    },
    piggy: {
      username: 'Piggy Bot',
      icon_url: 'https://s3.amazonaws.com/subtext-misc/mascot/piggy.jpg'
    }
  }

  WEBHOOK_URLS = {
    socialmedia: 'https://hooks.slack.com/services/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'
  }

  def send_published_content_notification(content)
    text = "#{content.organization.name} has published a post called #{content.title}: https://dailyuv.com/feed/#{content.id}"
    notifier = Slack::Notifier.new(WEBHOOK_URLS[:socialmedia])
    opts = {
      text: text
    }.merge(BOTS[:piggy])
    notifier.post(opts)
  end
end