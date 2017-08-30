module SearchIndexing
  class MarketSerializer < ContentSerializer
    attributes :sold, :cost, :contact_phone, :contact_email


    def cost
      object.channel.try :cost
    end

    def sold
      object.channel.try :sold
    end

    def contact_phone
      object.channel.try :contact_phone
    end

    def contact_email
      object.channel.try :contact_email
    end
  end
end
