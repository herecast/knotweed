# frozen_string_literal: true

module MailchimpService
  class CampaignSerializer < ActiveModel::Serializer
    root false
    attributes :type, :recipients, :settings, :tracking

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
        title: object.title,
        subject_line: object.subject,
        from_name: object.from_name,
        reply_to: object.reply_to
      }
    end

    def tracking
      {
        google_analytics: object.ga_tag
      }
    end
  end
end
