class Event < ActiveRecord::Base
  belongs_to :content
  has_one :source, through: :content, class_name: "Publication", foreign_key: "source_id"
  has_one :content_category, through: :content
  has_many :images, through: :content
  has_many :repositories, through: :content
  has_one :import_location, through: :content

  # just temporary to make app work before we move the business_location association
  # entirely to this model
  has_one :business_location, through: :content

  belongs_to :venue, class_name: "BusinessLocation"
  accepts_nested_attributes_for :venue,
    reject_if: proc { |attributes| attributes['name'].blank? and attributes['address'].blank? }

  validates_presence_of :content_id, :start_date

  attr_accessible :content_id, :cost, :end_date, :event_type, :event_url, :featured, 
    :links, :sponsor, :sponsor_url, :start_date, :venue_id, :venue, :content

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
end
