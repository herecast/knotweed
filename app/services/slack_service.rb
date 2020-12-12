# frozen_string_literal: true

module SlackService
  module_function

  BOTS = {
    chaco: {
      username: 'Chaco Bot',
      icon_url: 'https://s3.amazonaws.com/subtext-misc/mascot/chaco.jpg'
    },
    piggy: {
      username: 'Piggy Bot',
      icon_url: 'https://s3.amazonaws.com/subtext-misc/mascot/piggy.jpg'
    }
  }.freeze

  WEBHOOK_URLS = {
    socialmedia: nil,
    dev_private: nil
  }.freeze

  def send_published_content_notification(content)
    text = "<@jsensenich> #{content.caster.handle} has published a post!"
    notifier = Slack::Notifier.new(WEBHOOK_URLS[:socialmedia])
    opts = {
      text: text,
      attachments: [{
        title: content.title,
        text: "https://herecast.us/#{content.id}",
        color: '3CB371'
      }]
    }.merge(BOTS[:piggy])
    notifier.post(opts)
  end

  def send_mailchimp_error_message(text)
    notifier = Slack::Notifier.new(WEBHOOK_URLS[:dev_private])
    notifier.post(text: text)
  end
end
