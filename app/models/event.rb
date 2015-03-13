# == Schema Information
#
# Table name: events
#
#  id            :integer          not null, primary key
#  event_type    :string(255)
#  venue_id      :integer
#  cost          :string(255)
#  event_url     :string(255)
#  sponsor       :string(255)
#  sponsor_url   :string(255)
#  links         :text
#  featured      :boolean
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  contact_phone :string(255)
#  contact_email :string(255)
#  contact_url   :string(255)
#

class Event < ActiveRecord::Base
  has_one :content, as: :channel
  accepts_nested_attributes_for :content
  attr_accessible :content_attributes
  validates_associated :content

  has_one :source, through: :content, class_name: "Publication", foreign_key: "publication_id"
  has_one :content_category, through: :content
  has_many :images, through: :content
  has_many :repositories, through: :content
  has_one :import_location, through: :content

  belongs_to :venue, class_name: "BusinessLocation", foreign_key: "venue_id"
  accepts_nested_attributes_for :venue,
    reject_if: proc { |attributes| attributes['name'].blank? and attributes['address'].blank? }
  attr_accessible :venue_attributes, :venue_id

  # event instances represent individual datetimes for events that might occur more than once
  # they can also have a subtitle and description that "override" the master 
  has_many :event_instances
  validates_associated :event_instances # at least one must exist

  accepts_nested_attributes_for :event_instances, allow_destroy: true
  attr_accessible :event_instances_attributes

  # we can either remove this validation (the path I chose) OR
  # make the events#create action a lot more complex in that it would have
  # to first save and create the content, then save the event.
  # validates_presence_of :content_id

  attr_accessible :content, :cost, :event_type, :event_url, :featured,
    :links, :sponsor, :sponsor_url, :venue, :contact_phone, :contact_email, :contact_url

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
    [:id, :title, :event_type, :sponsor, :venue,
             :featured]
  end

end