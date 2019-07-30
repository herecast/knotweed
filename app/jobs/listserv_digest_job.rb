# frozen_string_literal: true

class ListservDigestJob < ApplicationJob
  def perform(listserv, timestamp)
    @listserv = listserv

    locations = @listserv.locations

    if @listserv.send_digest? && @listserv.active? && locations.count > 0

      digests = []

      # map campaigns to location_ids so we can easily associate as we iterate through subscription locations
      # seems a little better than querying campaigns (with a literal query) for every location
      if @listserv.campaigns.present?
        location_campaigns = {}
        @listserv.campaigns.each do |campaign|
          campaign.community_ids.each do |l_id|
            location_campaigns[l_id] = campaign
          end
        end
      end

      locations.each do |loc|
        loc_ids_for_query = loc.location_ids_within_fifty_miles
        location_digest_contents_count = @listserv.digest_contents(loc_ids_for_query).count

        if location_digest_contents_count >= @listserv.post_threshold
          digest_attrs = digest_attributes(loc_ids_for_query)

          if location_campaigns.present? and location_campaigns[loc.id].present?
            campaign = location_campaigns[loc.id]
            campaign_attrs = {}
            campaign_attrs[:preheader] = campaign.preheader if campaign.preheader?
            campaign_attrs[:sponsored_by] = campaign.sponsored_by if campaign.sponsored_by?
            campaign_attrs[:promotion_ids] = campaign.promotion_ids if campaign.promotion_ids?
            campaign_attrs[:title] = campaign.title if campaign.title?
            digest_attrs = digest_attrs.merge(campaign_attrs)
          end

          digests << ListservDigest.new(digest_attrs)
        end
      end

      @listserv.update last_digest_generation_time: Time.current

      digests.each do |digest|
        next unless digest.contents.any?

        if digest.subscriptions.any?
          digest.save!
          ListservDigestMailer.digest(digest).deliver_now
        end
      end
    end
  end

  private

  def digest_attributes(location_ids)
    {
      listserv: @listserv,
      subject: (@listserv.digest_subject? ? @listserv.digest_subject : "#{@listserv.name} Digest"),
      from_name: @listserv.sender_name? ? @listserv.sender_name : @listserv.name,
      reply_to: @listserv.digest_reply_to,
      template: @listserv.template,
      sponsored_by: @listserv.sponsored_by,
      promotion_ids: @listserv.promotion_ids,
      title: (@listserv.digest_subject? ? @listserv.digest_subject : "#{@listserv.name} Digest"),
      contents: @listserv.digest_contents(location_ids),
      subscriptions: subscriptions_for_location(location_ids)
    }
  end

  def subscriptions_for_location(location_ids)
    @listserv.subscriptions.joins('INNER JOIN users on subscriptions.user_id = users.id')
             .where(users: { location_id: location_ids })
             .where('subscriptions.confirmed_at IS NOT NULL')
             .where('subscriptions.unsubscribed_at IS NULL')
  end

end
