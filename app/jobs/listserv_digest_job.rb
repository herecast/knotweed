class ListservDigestJob < ApplicationJob
  def perform(listserv)
    @listserv = listserv

    if @listserv.send_digest? && @listserv.active?

      digests = []
      if @listserv.campaigns.present?
        @listserv.campaigns.each do |campaign|
          campaign_attrs = {
            contents: contents_for_campaign(campaign),
            location_ids: campaign.community_ids,
            subscription_ids: subscription_ids_for_campaign(campaign)
          }
          campaign_attrs[:preheader] = campaign.preheader if campaign.preheader?
          campaign_attrs[:sponsored_by] = campaign.sponsored_by if campaign.sponsored_by?
          campaign_attrs[:promotion_ids] = campaign.promotion_ids if campaign.promotion_ids?
          campaign_attrs[:title] = campaign.title if campaign.title?
          if campaign_post_count_above_threshold?(campaign)
            digests << ListservDigest.new(digest_attributes.merge(campaign_attrs))
          end
        end
      else
        unless @listserv.custom_digest? && custom_query_count < @listserv.post_threshold
          digests << ListservDigest.new(digest_attributes)
        end
      end

      @listserv.update last_digest_generation_time: Time.current

      digests.each do |digest|
        if digest.contents.any?
          if digest.subscriptions.any?
            digest.save!
            ListservDigestMailer.digest(digest).deliver_now
          end
        end
      end
    end
  end

  private

  def digest_attributes
    {
      listserv: @listserv,
      subject: (@listserv.digest_subject? ? @listserv.digest_subject : "#{@listserv.name} Digest"),
      from_name: @listserv.sender_name? ? @listserv.sender_name : @listserv.name,
      reply_to: @listserv.digest_reply_to,
      template: @listserv.template,
      sponsored_by: @listserv.sponsored_by,
      promotion_ids: @listserv.promotion_ids,
      title: (@listserv.digest_subject? ? @listserv.digest_subject : "#{@listserv.name} Digest")
    }.tap do |attrs|
      if @listserv.custom_digest?
        unless @listserv.campaigns.present?
          contents = @listserv.contents_from_custom_query
          attrs.merge!({
                         contents: contents,
                         subscriptions: @listserv.subscriptions.active
                       })
        end
      end
    end
  end

  def subscription_ids_for_campaign(campaign)
    if campaign.community_ids.any?
      # can't use the active scope here out of the box because of the ambiguous field names
      # when we join
      @listserv.subscriptions.joins('INNER JOIN users on subscriptions.user_id = users.id')
               .where('users.location_id in (?)', campaign.community_ids)
               .where('subscriptions.confirmed_at IS NOT NULL')
               .where('subscriptions.unsubscribed_at IS NULL')
               .pluck(:id)
    else
      @listserv.subscriptions.active.pluck(:id)
    end
  end

  def contents_for_campaign(campaign)
    if campaign.digest_query?
      campaign.contents_from_custom_query
    else
      @listserv.contents_from_custom_query
    end
  end

  def campaign_post_count_above_threshold?(campaign)
    @listserv.post_threshold <= contents_for_campaign(campaign).count
  end

  def custom_query_count
    @listserv.try(:contents_from_custom_query).try(:count) || 0
  end
end
