# frozen_string_literal: true

class FeedContentVanillaSerializer
  def self.call(*args)
    new(*args).call
  end

  def initialize(records)
    @records = records
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
        content: content(record.content),
        organization: organization(record.organization),
        carousel: carousel(record.carousel)
      }
    end
  end

  def content(raw_content)
    if raw_content.present?
      Api::V3::HashieMashes::ContentSerializer.new(raw_content).as_json['content']
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
        contents: carousel_contents(raw_carousel.contents),
        query_params: raw_carousel.query_params
      }
    end
  end

  def carousel_organizations(raw_organizations)
    raw_organizations.map do |raw_organization|
      Api::V3::OrganizationSerializer.new(raw_organization).as_json['organization']
    end
  end

  def carousel_contents(raw_contents)
    raw_contents.map do |raw_content|
      Api::V3::HashieMashes::ContentSerializer.new(raw_content).as_json['content']
    end
  end
end
