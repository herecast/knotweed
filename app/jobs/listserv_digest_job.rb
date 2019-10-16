# frozen_string_literal: true

class ListservDigestJob < ApplicationJob
  def perform(listserv)
    @listserv = listserv

    locations = @listserv.locations

    if @listserv.send_digest? && @listserv.active? && locations.count > 0

      digests = []

      # map campaigns to location_ids so we can easily associate as we iterate through subscription locations
      # seems a little better than querying campaigns (with a literal query) for every location
      location_campaigns = {}
      if @listserv.campaigns.present?
        @listserv.campaigns.each do |campaign|
          campaign.community_ids.each do |l_id|
            location_campaigns[l_id] = campaign
          end
        end
      end

      locations.each do |location|
        location_digest_contents_count = @listserv.digest_contents(location.location_ids_within_fifty_miles).count

        if location_digest_contents_count >= @listserv.post_threshold
          opts = {
            listserv: listserv,
            location: location,
            campaigns: location_campaigns
          }
          digests << Outreach::BuildDigest.call(opts)
        end
      end

      @listserv.update last_digest_generation_time: Time.current

      digests.each do |digest|
        next unless digest.contents.any?

        if digest.subscriptions.any?
          digest.save!

          Outreach::ScheduleDigest.call(digest)
        end
      end
    end
  end
end
