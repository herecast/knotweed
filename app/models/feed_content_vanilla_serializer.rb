class FeedContentVanillaSerializer

  def self.call(*args)
    self.new(*args).call
  end

  def initialize(records:, opts:)
    @records       = records
    @opts          = opts
  end

  def call
    {
      feed_items: feed_items
    }
  end


  private

    def feed_items
      @records.map do |record|
        {
          id: record.id,
          model_type: record.model_type,
          feed_content: feed_content(record.feed_content),
          organization: organization(record.organization),
          carousel: carousel(record.carousel)
        }
      end
    end

    def feed_content(raw_feed_content)
      if raw_feed_content.present?
        Api::V3::HashieMashes::FeedContentSerializer.new(raw_feed_content, @opts).as_json['feed_content']
      end
    end

    def organization(raw_organization)
      if raw_organization.present?
        Api::V3::OrganizationSerializer.new(raw_organization).as_json['organization']
      end
    end

    def carousel(raw_carousel)
      if raw_carousel.present?
        {
          id: raw_carousel.id,
          query: raw_carousel.query,
          carousel_type: raw_carousel.carousel_type,
          title: raw_carousel.title,
          organizations: carousel_organizations(raw_carousel.organizations),
          feed_contents: carousel_feed_contents(raw_carousel.feed_contents),
          query_params: raw_carousel.query_params
        }
      end
    end

    def carousel_organizations(raw_organizations)
      raw_organizations.map do |raw_organization|
        Api::V3::OrganizationSerializer.new(raw_organization).as_json['organization']
      end
    end

    def carousel_feed_contents(raw_feed_contents)
      raw_feed_contents.map do |raw_feed_content|
        Api::V3::HashieMashes::FeedContentSerializer.new(raw_feed_content, @opts).as_json['feed_content']
      end
    end

end