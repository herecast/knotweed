# == Schema Information
#
# Table name: events
#
#  id          :integer          not null, primary key
#  content_id  :integer
#  event_type  :string(255)
#  start_date  :datetime
#  end_date    :datetime
#  venue_id    :integer
#  cost        :string(255)
#  event_url   :string(255)
#  sponsor     :string(255)
#  sponsor_url :string(255)
#  links       :text
#  featured    :boolean
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Event < ActiveRecord::Base
  belongs_to :content
  has_one :source, through: :content, class_name: "Publication", foreign_key: "source_id"
  has_one :content_category, through: :content
  has_many :images, through: :content
  has_many :repositories, through: :content
  has_one :import_location, through: :content

  belongs_to :venue, class_name: "BusinessLocation", foreign_key: "venue_id"
  accepts_nested_attributes_for :venue,
    reject_if: proc { |attributes| attributes['name'].blank? and attributes['address'].blank? }
  attr_accessible :venue_attributes, :venue_id

  validates_presence_of :content_id, :start_date

  attr_accessible :content_id, :cost, :end_date, :event_type, :event_url, :featured, 
    :links, :sponsor, :sponsor_url, :start_date, :venue, :content, :description

  serialize :links, Hash

  # this callback allows us to essentially forget that the associated content
  # exists (and helps us maintain legacy code) because it means we can do things
  # like this:
  #     event.title = "New Title"
  #     event.save
  #  and end up with the event's content record's title updated.
  after_save do |event|
    event.content.save
  end

  # override default method_missing to pipe through any attribute calls that aren't on the
  # event model directly through to the attached content record.
  #
  # For example, calling event.title will return the equivalent of
  # event.content.title.
  #
  # If performance becomes a major issue, this method might be worth
  # revisiting, but I don't think it is a big problem since we're
  # only working with individual records here.
  #
  # as we expand to having multiple "channels" or whatever we're calling them,
  # we will probably want to factor this out into a class of its own that each
  # submodel inherits from
  def method_missing(method, *args, &block)
    if respond_to_without_attributes?(method)
      send(method, *args, &block)
    else
      if content.respond_to?(method)
        content.send(method, *args, &block)
      else
        super
      end
    end
  end

  # because the text field of the Content model is called "content" 
  # we can't use our method_missing override to access it, 
  # so this method just calls content.content
  def description
    content.content
  end
  def description=(new_desc)
    content.raw_content = new_desc
  end

  # field sets for API responses
  def self.truncated_event_fields
    [:id, :title, :subtitle, :start_date, :event_type, :sponsor,
             :featured]
  end
  
  def self.start_date_only_fields
    [:id, :start_date]
  end

end
