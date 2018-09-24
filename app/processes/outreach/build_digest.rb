module Outreach
  class BuildDigest

    def self.call(*args)
      self.new(*args).call
    end

    def initialize(listserv)
      @listserv = listserv
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
          title: (@listserv.digest_subject? ? @listserv.digest_subject : "#{@listserv.name} Digest")
        }.tap do |attrs|
          if @listserv.custom_digest?
            contents = @listserv.contents_from_custom_query
            attrs.merge!({
              contents: contents,
              subscriptions: @listserv.subscriptions.active
            })
          end
        end
      end

  end
end