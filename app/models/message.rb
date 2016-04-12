# == Schema Information
#
# Table name: messages
#
#  id            :integer          not null, primary key
#  created_by_id :integer
#  controller    :string(255)
#  action        :string(255)
#  start_date    :datetime
#  end_date      :datetime
#  content       :text
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class Message < ActiveRecord::Base
  belongs_to :created_by, class_name: "User"
  has_and_belongs_to_many :consumer_apps
  attr_accessible :action, :content, :controller, :created_by, :end_date, :start_date, :consumer_app_ids

  scope :active, lambda { where("start_date < ? AND (end_date > ? or end_date IS NULL)", Time.zone.now, Time.zone.now) }
  
  default_scope { order("start_date DESC") }

  validates_presence_of :controller, :content, :start_date
  validate :end_date_greater_than_start_date

  CONTROLLER_OPTIONS = %w(contents events registrations home market_posts)
  ACTION_OPTIONS = %w(index show edit local_content subserve tott)

  def active?
    if start_date < Time.zone.now and (end_date.nil? or end_date > Time.zone.now)
      true
    else
      false
    end
  end

  def end_date_greater_than_start_date
    if end_date.present? and end_date <= start_date
      errors.add :end_date, "End date must be later than start date"
    end
  end

end
