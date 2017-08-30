module SearchIndexing
  class EventSerializer < ContentSerializer
    attributes :cost, :cost_type, :contact_phone, :contact_email

    has_one :venue, serializer: SearchIndexing::VenueSerializer
    has_many :event_instances, serializer: SearchIndexing::EventInstanceSerializer

    def event_instances
      object.channel.try(:event_instances) || []
    end

    def venue
      object.channel.try :venue
    end

    def cost
      object.channel.try :cost
    end

    def cost_type
      if object.channel_type == 'Event'
        object.channel.try(:cost_type)
      end
    end

    def contact_phone
      object.channel.try :contact_phone
    end

    def contact_email
      object.channel.try :contact_email
    end

    def event_id
      object.channel_id
    end

    def registration_deadline
      object.channel.try :registration_deadline
    end

  end
end
