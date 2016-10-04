# == Schema Information
#
# Table name: market_posts
#
#  id                       :integer          not null, primary key
#  cost                     :string(255)
#  contact_phone            :string(255)
#  contact_email            :string(255)
#  contact_url              :string(255)
#  locate_name              :string(255)
#  locate_address           :string(255)
#  latitude                 :float
#  longitude                :float
#  locate_include_name      :boolean
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  status                   :string(255)
#  preferred_contact_method :string(255)
#

class MarketPost < ActiveRecord::Base

  has_one :content, as: :channel
  accepts_nested_attributes_for :content
  validates_associated :content
  validates :contact_phone, format: { without: /[a-wyzA-WYZ]/ }

  has_one :source, through: :content, class_name: "Organization", foreign_key: "organization_id"
  has_one :content_category, through: :content
  has_many :images, through: :content
  has_many :repositories, through: :content
  has_one :import_location, through: :content

  geocoded_by :locate_address

  after_validation :geocode, if: ->(obj){ obj.locate_address.present? and obj.locate_address_changed?}


  # this callback allows us to essentially forget that the associated content
  # exists (and helps us maintain legacy code) because it means we can do things
  # like this:
  #     market_post.title = "New Title"
  #     market_post.save
  #  and end up with the market_post's content record's title updated.
  after_save do |market_post|
    market_post.content.save
  end


  # override default method_missing to pipe through any attribute calls that aren't on the
  # event model directly through to the attached content record.
  #
  # For example, calling event.title will return the equivalent of
  # market_post.content.title.
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

end
