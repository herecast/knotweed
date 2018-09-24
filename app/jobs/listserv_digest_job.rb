class ListservDigestJob < ApplicationJob
  def perform(listserv)
    @listserv = listserv

    if @listserv.send_digest? && @listserv.active?
      @listserv.update last_digest_generation_time: Time.current

      unless custom_digest_below_threshold?
        digest = Outreach::BuildDigest.call(listserv)
        if digest.contents.any? && digest.subscriptions.any?
          digest.save!
          Outreach::ScheduleDigest.call(digest)
        end
      end
    end
  end

  private

    def custom_digest_below_threshold?
      @listserv.custom_digest? && custom_query_count < @listserv.post_threshold
    end

    def custom_query_count
      @listserv.try(:contents_from_custom_query).try(:count) || 0
    end

end
