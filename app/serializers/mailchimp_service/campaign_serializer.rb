module MailchimpService
  class CampaignSerializer < ActiveModel::Serializer
    root false
    attributes :type, :recipients, :settings

    def type
      'regular'
    end

    def recipients
      {
        list_id: object.listserv.mc_list_id,
        segment_opts: {
          saved_segment_id: object.mc_segment_id.to_i
        }
      }
    end

    def settings
      {
        subject_line: object.subject,
        from_name: object.from_name,
        reply_to: object.reply_to
      }
    end
  end
end
