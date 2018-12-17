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
    newbloggers: 'https://hooks.slack.com/services/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'
  }.freeze

  def send_published_content_notification(content)
    text = "<@jsensenich> #{content.organization.name} has published a post!"
    notifier = Slack::Notifier.new(WEBHOOK_URLS[:socialmedia])
    opts = {
      text: text,
      attachments: [{
        title: content.title,
        text: "https://dailyuv.com/#{content.id}",
        color: "3CB371"
      }]
    }.merge(BOTS[:piggy])
    notifier.post(opts)
  end

  def send_new_blogger_alert(user:, organization:)
    text = "#{user.name} just created the blog #{organization.name}."
    notifier = Slack::Notifier.new(WEBHOOK_URLS[:newbloggers])
    opts = {
      text: 'New blogger on DailyUV!',
      attachments: [{
        title: text,
        text: organization.profile_link,
        color: '000099'
      }]
    }.merge(BOTS[:chaco])
    notifier.post(opts)
  end
end
