# Sends email notifications (via MailChimp) about published posts to organization subscribers.

class NotifySubscribersJob < ApplicationJob
  include ContentsHelper
  include EmailTemplateHelper

  ERB_TEMPLATE_PATH = "#{Rails.root}/app/views/subscriptions_notifications/notification.html.erb"

  def perform(post_id)
    post = Content.find_by(id: post_id)
    return unless post

    # If a notification has already been sent, the game is over, so do nothing.
    return if notification_already_sent(post)

    # In all cases, if the post already has a MailChimp notification campaign, cancel it.
    # If we still need a campaign (decided below), we'll create a new one below.
    if post.subscriber_mc_identifier.present?
      SubscriptionsMailchimpClient.cancel_campaign(campaign_identifier: post.subscriber_mc_identifier)
      post.update_attribute(:subscriber_mc_identifier, nil)  # No callbacks!
    end

    # Ignore posts that would produce malformed notifications.
    return unless (title              = post.title.presence)
    return unless (author_name        = post.author_name.presence || post.created_by&.name)
    return unless (organization_name  = post.organization_name.presence)
    return unless (mc_list_identifier = SubscriberListIdFetcher.new.call(post.organization).presence)

    # If this point is reached, we have a viable post about which we can notify subscribers.
    # We will send the notification as HTML.
    notification_html = generate_html(title,
                                      author_name,
                                      organization_name,
                                      url_for_consumer_app("/organizations/#{post.organization_id}"),
                                      url_for_consumer_app(ux2_content_path(post)))

    # Create a new MailChimp campaign for this mailing, then send the mailing to the subscribers in
    # the organization's list.
    campaign_id = SubscriptionsMailchimpClient.create_campaign(list_identifier: mc_list_identifier,
                                                               subject:         "See the new post from #{organization_name}",
                                                               title:           title,
                                                               from_name:       organization_name,
                                                               reply_to:        "dailyUV@subtext.org")
    SubscriptionsMailchimpClient.create_content(campaign_identifier: campaign_id,
                                                html:                notification_html)

    send_at = post.pubdate
    # MailChimp is fussy about schedules being in the future.
    if send_at && send_at > 2.minutes.from_now
      SubscriptionsMailchimpClient.schedule_campaign(campaign_identifier: campaign_id, send_at: send_at)
    else
      SubscriptionsMailchimpClient.send_campaign(campaign_identifier: campaign_id)
    end

    post.update_attribute(:subscriber_mc_identifier, campaign_id)    # No callbacks!
  end

  private

  def notification_already_sent(post)
    if post.subscriber_mc_identifier.present?
      SubscriptionsMailchimpClient.get_status(campaign_identifier: post.subscriber_mc_identifier) =~ /sent/i
    end
  end

  def generate_html(title, author_name, organization_name, organization_url, post_url)
    @title, @author_name, @organization_name, @organization_url, @post_url =
      title, author_name, organization_name, organization_url, post_url
    ERB.new(File.read(ERB_TEMPLATE_PATH)).result(binding)
  end
end


class NotifySubscribersJob::SubscriberListIdFetcher

  # We have two ways to match an organization to a MailChimp list: by +subscribe_url+ and by +name+.
  def call(organization)
    return nil unless subscribe_url = organization.subscribe_url.presence

    list = lookup_by_subscribe_url_short(subscribe_url) || lookup_by_name(organization.name)
    list.presence && list['id']
  end

  private

  def lookup_by_name(name)
    name = name.to_s.squish
    return nil if name.empty?

    all_lists.find { |list| list['name'].to_s.squish == name }
  end

  def lookup_by_subscribe_url_short(url)
    return nil unless url.present?

    all_lists.find { |list| list['subscribe_url_short'] == url }
  end

  def all_lists
    @lists ||= SubscriptionsMailchimpClient.lists.to_a
  end
end
