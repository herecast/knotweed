module MailchimpService
  class CampaignSerializer < ActiveModel::Serializer
    root false
    attributes :type, :recipients, :settings

    def type
      'regular'
    end

    def recipients
      {
        list_id: object.listserv.mc_list_id
      }
    end

    def settings
      {
        subject_line: "#{object.listserv.name} Digest",
        from_name: object.listserv.name,
        reply_to: object.listserv.digest_reply_to
      }
    end
  end
end
