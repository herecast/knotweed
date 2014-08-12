class ContentSerializer < ActiveModel::Serializer

  attributes :id, :title, :start_date, :end_date, :event_type, :host_organization,
    :cost, :recurrence, :content, :featured, :links

  self.root = false

  has_one :business_location
  has_many :images

  def filter(keys)
    if object.category == "event"
      keys
    else
      # we will at some point want to be defining the regular contents attributes here
      # and filtering them out of events, but for now, this is fine.
      [keys[0]]
    end
  end

end
