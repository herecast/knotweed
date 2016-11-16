# == Schema Information
#
# Table name: received_emails
#
#  id           :integer          not null, primary key
#  file_uri     :string
#  purpose      :string
#  processed_at :datetime
#  from         :string
#  to           :string
#  message_id   :string
#  record_id    :integer
#  record_type  :string
#  result       :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require 'open-uri-s3'

class ReceivedEmail < ActiveRecord::Base
  belongs_to :record, polymorphic: true

  validates :file_uri, presence: true, uniqueness: {case_sensitive: false}
  validates :message_id, uniqueness: {case_sensitive: false}, if: :message_id?

  delegate :subject, to: :message_object

  class_attribute :sanitize_config
  self.sanitize_config = Sanitize::Config::RELAXED

  def body
    return enriched_text if enriched_text?
    return sanitized_html if html?
    return text
  end

  def to=e
    write_attribute :to, e.try(:downcase)
  end

  def from=e
    write_attribute :from, e.try(:downcase)
  end

  def sanitized_html
    Sanitize.fragment(html, self.class.sanitize_config)
  end

  def html
    if message_object.multipart?
      message_object.html_part.try(:decoded)
    else
      nil
    end
  end

  def html?
    html.present?
  end

  def text
    if message_object.multipart?
      message_object.text_part.try(:decoded)
    else
      message_object.body.try(:decoded)
    end
  end

  def enriched_text
    if message_object.multipart?
      message_object.parts.select{|p| p.content_type.include?('text/enriched')}.first.try(:decoded)
    else
      nil
    end
  end

  def enriched_text?
    enriched_text.present?
  end

  def sender_name
    if message_object[:from]
      return extract_name message_object[:from].decoded
    end
    nil
  end

  def message_object
    @message_object ||=
      Mail.new(get_raw_email)
  end

  def preprocess
    self.message_id = message_object.message_id
    self.to = message_object.to.join(', ')
    self.from = message_object.from.first
  end

  private
  def get_raw_email
    open(file_uri).read
  end

  def extract_name(from_string)
    matches = from_string.match(/^["|']?([\w\s\+,_\-\.]+)["|']?[ ]?<.*>/)
    if matches
      return matches[1].to_s.strip
    else
      from_string.split(',').first.match(/[<]?(.*)@[>]?/)[1]
    end
  end
end
