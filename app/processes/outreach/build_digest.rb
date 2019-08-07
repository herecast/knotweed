module Outreach
  class BuildDigest

    def self.call(*args)
      self.new(*args).call
    end

    def initialize(listserv:, location:, campaigns: {})
      @listserv  = listserv
      @location  = location
      @campaigns = campaigns
    end

    def call
      return ListservDigest.new(digest_attributes)
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
          title: (@listserv.digest_subject? ? @listserv.digest_subject : "#{@listserv.name} Digest"),
          contents: @listserv.digest_contents(@location.location_ids_within_fifty_miles),
          subscriptions: subscriptions_for_location,
          location: @location
        }.tap do |attrs|
          if campaign = @campaigns[@location.id].presence
            attrs[:preheader] = campaign.preheader if campaign.preheader?
            attrs[:sponsored_by] = campaign.sponsored_by if campaign.sponsored_by?
            attrs[:promotion_ids] = campaign.promotion_ids if campaign.promotion_ids?
            attrs[:title] = campaign.title if campaign.title?
          end
        end
      end

      def subscriptions_for_location
        @listserv.subscriptions.joins('INNER JOIN users on subscriptions.user_id = users.id')
                 .where(users: { location_id: @location.id })
                 .active
      end

  end
end