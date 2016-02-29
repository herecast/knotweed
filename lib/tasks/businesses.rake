namespace :businesses do

  desc 'Import seed data for business services directory'
  task import_json: :environment do
    # import categories first so we can then assign businesses to the appropriate categories
    cat_data_path = File.join(File.dirname(__FILE__),'business_categories.json')
    cat_file = File.read(cat_data_path)
    categories = JSON.parse(cat_file)

    # need to create root level categories first so children can be persisted properly
    categories.select{|c| c['parent_cats'].empty? }.each do |c|
      BusinessCategory.find_or_create_by_name(
        description: c['subtitle'],
        name: c['title'],
        icon_class: c['icon_class']
      )
    end

    # now create children...the structure of the incoming data means we have to filter
    # the JSON array to find the parent referred to by the `cat_id` which is something we're
    # not storing, so it's not the most efficient thing in the world, but with only 84
    # items in the data set, it's not a big problem.
    categories.select{|c| c['parent_cats'].present? }.each do |c|
      parents = []
      c['parent_cats'].each do |pc_id|
        parent_name = categories.select{|p| p['cat_id'] == pc_id}.first['title']
        parents << BusinessCategory.find_by_name(parent_name)
      end
      new_cat = BusinessCategory.find_or_create_by_name(
        name: c['title'],
        description: c['subtitle'],
        icon_class: c['icon_class']
      )
      new_cat.parents = parents
    end
    
    biz_data_path = File.join(File.dirname(__FILE__),'business_services_directory.json')
    biz_file = File.read(biz_data_path)
    businesses = JSON.parse(biz_file)

    # create business profiles for each record
    businesses.each do |b|
      content_attrs = {
        pubdate: Time.zone.now,
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
