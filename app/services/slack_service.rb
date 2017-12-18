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
    socialmedia: 'https://hooks.slack.com/services/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',
    storyteller_posts: 'https://hooks.slack.com/services/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'
  }

  def send_published_content_notification(content)
    text = "<@jsensenich> #{content.organization.name} has published a post!"
    notifier = Slack::Notifier.new(WEBHOOK_URLS[:socialmedia])
    opts = {
      text: text,
      attachments: [{
        title: content.title,
        text: "https://dailyuv.com/feed/#{content.id}",
        color: "3CB371"
      }]
    }.merge(BOTS[:piggy])
    notifier.post(opts)
  end

  def send_storyteller_post_notification(content)
    text = "<@jsensenich> #{content.created_by.name} has published a post for #{content.organization&.name}!"
    url_appendage = content.is_event? ? "#{content.id}/#{content.channel.next_or_first_instance.id}" : content.id
    notifier = Slack::Notifier.new(WEBHOOK_URLS[:storyteller_posts])
    opts = {
      text: text,
      attachments: [{
        title: content.title,
        text: "https://dailyuv.com/feed/#{url_appendage}",
        color: "cc3366"
      }]
    }.merge(BOTS[:chaco])
    notifier.post(opts)
  end
end