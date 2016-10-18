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
          campaign_attrs[:sponsored_by] = campaign.sponsored_by if campaign.sponsored_by?
          campaign_attrs[:promotion_id] = campaign.promotion_id if campaign.promotion_id?
          digests << ListservDigest.new(digest_attributes.merge(campaign_attrs))
        end
      else
        digests << ListservDigest.new(digest_attributes.merge({
          contents: contents_for_listserv_digest,
          subscription_ids: @listserv.subscriptions.active.pluck(:id)
        }))
      end

      @listserv.update last_digest_generation_time: Time.current

      digests.each do |digest|
        if digest.listserv_contents.any? || digest.contents.any?
          if digest.subscription_ids.any?
            digest.save!
            ListservDigestMailer.digest(digest).deliver_now
          end
        end
      end
    end
  end

  private
  def listserv_contents_verified_after(time)
    ListservContent\
      .where(listserv_id: @listserv.id)\
      .where("verified_at > ?", time)\
      .where('content_id IS NULL')
  end

  def contents_promoted_or_enhanced_after(time)
    (PromotionListserv\
      .where(listserv_id: @listserv.id)\
      .where('created_at > ?', time)\
      .includes(promotion: :content)\
      .collect{|pl| pl.promotion.content}\
      + ListservContent\
          .where(listserv_id: @listserv.id)\
          .where('content_id IS NOT NULL')\
          .where("verified_at > ?", time)\
          .includes(:content)\
          .collect{|lc| lc.content}).uniq
  end

  def digest_attributes
    {
      listserv: @listserv,
      subject: (@listserv.digest_subject? ? @listserv.digest_subject : "#{@listserv.name Digest}"),
      from_name: @listserv.sender_name? ? @listserv.sender_name : @listserv.name,
      reply_to: @listserv.digest_reply_to,
      template: @listserv.template,
      listserv_contents: listserv_contents_verified_after(
        @listserv.last_digest_generation_time || 1.month.ago
      ),
      sponsored_by: @listserv.sponsored_by,
      promotion_id: @listserv.promotion_id
    }
  end

  def contents_for_listserv_digest
    if @listserv.digest_query?
      @listserv.contents_from_custom_query
    else
      contents_promoted_or_enhanced_after(
        @listserv.last_digest_generation_time || 1.month.ago
      )
    end
  end

  def subscription_ids_for_campaign(campaign)
    if campaign.community_ids.any?
      # can't use the active scope here out of the box because of the ambiguous field names
      # when we join
      @listserv.subscriptions.joins('INNER JOIN users on subscriptions.user_id = users.id').
        where('users.location_id in (?)', campaign.community_ids).
        where('subscriptions.confirmed_at IS NOT NULL').
        where('subscriptions.unsubscribed_at IS NULL').
        pluck(:id)
    else
      @listserv.subscriptions.active.pluck(:id)
    end
  end

  def contents_for_campaign(campaign)
    if campaign.digest_query?
      campaign.contents_from_custom_query
    else
      contents_for_listserv_digest
    end
  end

end
