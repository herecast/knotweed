# == Schema Information
#
# Table name: listservs
#
#  id                    :integer          not null, primary key
#  name                  :string(255)
#  reverse_publish_email :string(255)
#  import_name           :string(255)
#  active                :boolean
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

class Listserv < ActiveRecord::Base
  has_many :promotion_listservs
  has_and_belongs_to_many :locations

  attr_accessible :active, :import_name, :name, :reverse_publish_email

  validates_uniqueness_of :reverse_publish_email
  
  default_scope { where active: true }

  # Sends the content to this listserv using ReversePublishMailer,
  # and adds a content_location record for the content using
  # the listserv's location
  def send_content_to_listserv(content, consumer_app=nil)
    ReversePublisher.mail_content_to_listservs(content, [self], consumer_app).deliver
    ReversePublisher.send_copy_to_sender_from_dailyuv(content).deliver
    if self.locations.present?
      self.locations.each do |l|
        content.locations << l unless content.locations.include? l
      end
    end
  end

  def add_listserv_location_to_content(content)
    if self.locations.present?
      self.locations.each do |l|
        content.locations << l unless content.locations.include? l
      end
    end
  end

end
