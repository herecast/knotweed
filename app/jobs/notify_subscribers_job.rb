# Synchronizes the given post's MailChimp email notification campaign with the post.
# The synchronization may involve creating a campaign for the give post, updating an unsent campaign, or
# halting the post's campaign.

class NotifySubscribersJob < ApplicationJob
  include ContentsHelper
  include EmailTemplateHelper

  ERB_NEWS_TEMPLATE_PATH = "#{Rails.root}/app/views/subscriptions_notifications/notification.html.erb"
  ERB_NON_NEWS_POST_TEMPLATE_PATH = "#{Rails.root}/app/views/subscriptions_notifications/organization_notification.html.erb"
  ERB_FEATURE_NOTIFICATION_TEMPLATE_PATH = "#{Rails.root}/app/views/subscriptions_notifications/feature_notification.html.erb"
  ERB_GARDENING_GUY_TEST_TEMPLATE_PATH = "#{Rails.root}/app/views/subscriptions_notifications/gardening_guy_test.html.erb"

  def perform(post)
    return unless !post.deleted_at && post.pubdate
    return if post.subscriber_mc_identifier.present?
    mc_list_identifier = SubscriberListIdFetcher.new.call(post.organization).presence

    if mc_list_identifier && list_has_subscribers(post.organization)
      campaign_id = SubscriptionsMailchimpClient.create_campaign(
        list_identifier: mc_list_identifier,
        subject:         campaign_subject(post),
        title:           post.title,
        from_name:       "#{post.organization_name} on DailyUV",
        reply_to:        campaign_reply_to
      )
      post.update_attribute(:subscriber_mc_identifier, campaign_id.presence)
    end

    synchronize_campaign(post)
  end

  private

  def campaign_reply_to
    "dailyUV@subtext.org"
  end

  def campaign_subject(post)
    if post.organization.feature_notification_org?
      "New DailyUV Features!"
    else
      "#{post.location.pretty_name} | #{post.title}"
    end
  end

  def synchronize_campaign(post)
    return unless post.subscriber_mc_identifier

    # Synchronize the campaign's HTML content, settings, and schedule with the post.
    path = appropriate_template_path(post)
    notification_html = generate_html(
      post.title,
      post.organization_name,
      url_for_consumer_app("/profile/#{post.organization_id}"),
      url_for_consumer_app(ux2_content_path(post)),
      post.organization.background_image_url,
      content_excerpt(post),
      path,
      post.organization.profile_image_url
    )

    SubscriptionsMailchimpClient.update_campaign(
      campaign_identifier: post.subscriber_mc_identifier,
      subject: campaign_subject(post),
      title: post.title,
      from_name: post.organization_name,
      reply_to: campaign_reply_to
    )

    SubscriptionsMailchimpClient.set_content(
      campaign_identifier: post.subscriber_mc_identifier,
      html: notification_html
    )

    # MailChimp is fussy about campaign only being scheduled for future times.
    # In case their clock is off a little, pad the time with a couple minutes.
    future_campaign_timing = [post.pubdate, Time.now].max + 2.minutes

    # MailChimp is fussy about schedules being on the quarter-hour (e.g. hh:00, hh:15, hh:30, or hh:45).
    timing = next_quarter_hour(future_campaign_timing)
    schedule_campaign(post.subscriber_mc_identifier, timing: timing)
  end

  def appropriate_template_path(content)
    if content.organization.name == "The Gardening Guy"
      ERB_GARDENING_GUY_TEST_TEMPLATE_PATH
    elsif content.organization.feature_notification_org?
      ERB_FEATURE_NOTIFICATION_TEMPLATE_PATH
    elsif [:event, :market, :talk].include?(content.content_type)
      ERB_NON_NEWS_POST_TEMPLATE_PATH
    else
      ERB_NEWS_TEMPLATE_PATH
    end
  end

  def next_quarter_hour(time)
    Time.at(((time - 1.second).to_f / 15.minutes.to_i).floor * 15.minutes.to_i) + 15.minutes
  end

  def notification_already_sent(post)
    if post.subscriber_mc_identifier.present?
      SubscriptionsMailchimpClient.get_status(campaign_identifier: post.subscriber_mc_identifier) =~ /sent/i
    end
  end

  def generate_html(title, organization_name, organization_url, post_url, banner_image_url, excerpt, path, profile_image_url)
    @title, @organization_name, @organization_url, @post_url, @banner_image_url, @excerpt, @profile_image_url =
      title, organization_name, organization_url, post_url, banner_image_url, excerpt, profile_image_url
    ERB.new(File.read(path)).result(binding)
  end

  def list_has_subscribers(organization)
    list = new_mailchimp_connection.lists.list({list_name: organization.name})['data'][0]
    return true unless list.present? # this could be a false indicator and the issue is covered elsewhere
    return list['stats']['member_count'] > 0
  end

  def schedule_campaign(campaign_id, timing: Time.current)
    new_mailchimp_connection.campaigns.schedule(campaign_id,
      next_quarter_hour(timing).utc.to_s.sub(' UTC', '')
    )
  end

  private

    def new_mailchimp_connection
      Mailchimp::API.new(Figaro.env.subscriptions_mailchimp_api_key)
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
