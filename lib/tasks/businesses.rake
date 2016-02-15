namespace :businesses do

  desc 'Import seed data for business services directory'
  task import_json: :environment do
    source_path = File.join(File.dirname(__FILE__),'business_services_directory.json')
    file = File.read(source_path)
    businesses = JSON.parse(file)

    # create business profiles for each record
    businesses.each do |b|
      content_attrs = {
        raw_content: b['details'],
        title: b['name']
      }

      business_location_attrs = {}
      [:phone, :email, :address, :city, :state, :zip, :hours, :service_radius, :latitude, :longitude].each do |attr|
        business_location_attrs[attr] = b[attr.to_s]
      end

      # if org already exists, associate with that.
      if org=Organization.find_by_name(b['name'])
        content_attrs[:organization_id] = org.id
        org.update_attribute :website, b['website']
      else # otherwise create new
        organization_attrs = {
          name: b['name'],
          website: b['website']
        }
        content_attrs[:organization_attributes] = organization_attrs
      end

      # find or create business categories and map to IDs
      category_ids = []
      b['categories'].each do |name|
        category_ids << BusinessCategory.find_or_create_by_name(name).id
      end

      bp=BusinessProfile.new(
        has_retail_location: (b['type'] == 'goes_to' ? true : false),
        content_attributes: content_attrs,
        business_location_attributes: business_location_attrs,
        business_category_ids: category_ids
      )

      if bp.save
        puts "Created #{bp.content.title} business profile with ID #{bp.id}"
      else
        puts "Error creating business profile #{b['name']}:\n #{bp.errors.messages}\n"
      end
    end
  end
end
