class UpdateContentLocations
  # Updates the content_locations ona Content record from
  # radius, and base_location_ids
  #
  # @param content [Content] record to update
  # @param promote_radius [Integer]
  # @param base_locations [Array(Location)] list of locations to base from
  def self.call(content, **opts)
    self.new(content, **opts).call
  end

  def initialize(content, promote_radius:, base_locations: [])
    @content = content
    @promote_radius = promote_radius
    @base_locations = base_locations
  end

  def call
    if @promote_radius.present? && @base_locations.present?
      if promote_radius_changed? || base_locations_changed?
        @content.promote_radius = @promote_radius
        rebuild_content_locations!
      end
    end
  end

  private
  def promote_radius_changed?
    @content.promote_radius != @promote_radius
  end

  def base_locations_changed?
    differences = content_base_locations - @base_locations | @base_locations - content_base_locations
    differences.any?
  end

  def content_base_locations
    @content.content_locations.select(&:base?).map(&:location)
  end

  def rebuild_content_locations!
    @content.content_locations = @base_locations.map do |bl|
      radius_locations = Location.consumer_active\
        .non_region\
        .within_radius_of(bl, @promote_radius) - [bl]

      [ContentLocation.new(
        location: bl,
        location_type: 'base')
      ] | radius_locations.map do |l|
        ContentLocation.new(location: l)
      end
    end.flatten
  end
end
