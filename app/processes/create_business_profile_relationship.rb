class CreateBusinessProfileRelationship

  def self.call(*args)
    self.new(*args).call
  end

  def initialize(opts)
    @business_profile = opts[:business_profile]
    @org_name         = opts[:org_name]
  end

  def call
    conditionally_build_business_profile
    ensure_business_location_hours_are_valid
    @content = Content.find_or_create_by(channel_id: @business_profile.id, channel_type: 'BusinessProfile')
    @organization = @content.organization || Organization.find_or_create_by(name: @org_name)
    update_default_content_attributes
    conditionally_update_organization_type
    update_business_location_org_id
    make_business_profile_exist
  end

  private

    def conditionally_build_business_profile
      if @business_profile.nil?
        business_location = BusinessLocation.create(name: @org_name)
        @business_profile = business_location.create_business_profile
      end
    end

    def ensure_business_location_hours_are_valid
      if @business_profile.business_location.hours == ''
        @business_profile.business_location.update_column(:hours, nil)
      end
    end

    def update_default_content_attributes
      @content.update_attributes({
        title: @organization.name,
        organization_id: @organization.id,
        pubdate: Time.current,
      })
    end

    def conditionally_update_organization_type
      @organization.update_attribute(:org_type, 'Business') if @organization.org_type.nil?
    end

    def update_business_location_org_id
      @business_profile.business_location.update_attribute(:organization_id, @organization.id)
    end

    def make_business_profile_exist
      @business_profile.update_attributes(existence: 1.0, archived: false)
    end

end
