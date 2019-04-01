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
        color: '3CB371'
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

  def send_new_blogger_email_capture(email)
    text = "Mobile blogger interest from #{email}"
    notifier = Slack::Notifier.new(WEBHOOK_URLS[:newbloggers])
    opts = {
      text: 'New blogger interest on mobile',
      attachments: [{
        title: text,
        color: '009900'
      }]
    }.merge(BOTS[:chaco])
    notifier.post(opts)
  end

  def send_new_blogger_error_alert(error:, user:, organization:)
    text = "There appears to be a problem signing #{user.email} up in Mailchimp "
    notifier = Slack::Notifier.new(WEBHOOK_URLS[:newbloggers])
    opts = {
      text: 'Problem with #{organization.name}',
      attachments: [{
        title: text,
        text: error.inspect,
        color: 'ff0000'
      }]
    }.merge(BOTS[:chaco])
    notifier.post(opts)
  end
end
