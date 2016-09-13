class ListservDigestJob < ApplicationJob
  def perform(listserv)
    @listserv = listserv

    if @listserv.send_digest? && @listserv.active?
      if @listserv.digest_query?
        digest = ListservDigest.new({
          listserv: @listserv,
          listserv_contents: listserv_contents_verified_after(
            listserv.last_digest_generation_time || 1.month.ago
          ),
          contents: contents_for_custom_digest
        })
      else
        digest = ListservDigest.new({
          listserv: @listserv,
          listserv_contents: listserv_contents_verified_after(
            listserv.last_digest_generation_time || 1.month.ago
          ),
          contents: contents_promoted_or_enhanced_after(
            listserv.last_digest_generation_time || 1.month.ago
          )
        })
      end

      if digest.listserv_contents.any? || digest.contents.any?
        digest.save!
        ListservDigestMailer.digest(digest).deliver_now
      end

      listserv.update last_digest_generation_time: Time.current
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

  def contents_for_custom_digest
    Content.where(id: @listserv.content_ids_for_results)
  end
end
