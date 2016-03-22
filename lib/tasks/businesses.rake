namespace :businesses do

  desc 'Import Factual categories via their API'
  task import_factual_categories: :environment do
    data = HTTParty.get('https://raw.githubusercontent.com/Factual/places/master/categories/factual_taxonomy.json')
    categories = JSON.parse(data)
    
    # first, we go through and create all the categories
    categories.each do |k,v| 
      # skip "1" because it's 'Factual Places' which isn't a real category
      # note, we also need to ignore parent references that point to this
      next if k == '1'
      if cat=BusinessCategory.where(source: 'Factual', source_id: k.to_i).first
        puts "Factual category #{v['labels']['en']} already exists\n"
      elsif cat=BusinessCategory.where(name: v['labels']['en']).first
        # add Factual source/id to our category so we can map Factual businesses
        # to this category
        cat.update_attributes({
          source: 'Factual',
          source_id: k.to_i
        })
      else # create new category
        BusinessCategory.create({
          source: 'Factual',
          source_id: k.to_i,
          name: v['labels']['en']
        })
      end
    end

    # unfortunately, we have to do this iteration twice to make the parent associations work.
    # The alternative would be to do a lot of parsing of the JSON and try to create each tier
    # separately from the top down...but that seems unnecessarily complex
    categories.each do |k,v|
      next if k == '1'
      cat = BusinessCategory.where(source: 'Factual', source_id: k.to_i).first
      if cat.present? and v['parents'].present?
        v['parents'].each do |p_id|
          next if p_id == '1' # skip 'Factual Places'
          parent = BusinessCategory.where(source: 'Factual', source_id: p_id.to_i).first
          if parent.present?
            cat.parents << parent unless cat.parents.include? parent
          end
        end
      end
    end
  end

  # NOTES on work left to do:
  # -- hours are not quite importing right when there's more than one entry
  desc 'Import Factual dataset'
  task :import_factual, [:dataset_path] => :environment do |t, args|
    existence_threshold = 0.4
    # unfortunately CSV doesn't like the way this file uses quotes so I'm just parsing line by line.
    File.foreach(args[:dataset_path]) do |line|
      row = line.split("\t")

      # first, we check to see if we already have the object in our database
      factual_id = row[0]
      existence = row[24].strip.to_f

      # if we don't have it in the database AND existence is below threshold, skip it
      existing_profile = BusinessProfile.where(source: 'Factual', source_id: factual_id).first
      next if existing_profile.nil? and existence < existence_threshold
        
      # deal with categories
      factual_category_ids = row[18].gsub(/[\[\]]/, '').split(',').map{|id| id.to_i}
      subtext_category_ids = []
      factual_category_ids.each do |id|
        bc = BusinessCategory.where(source: 'Factual', source_id: id).first
        subtext_category_ids << bc.id if bc.present?
      end

      hours = row[23].split(";").map do |h|
        BusinessProfile.convert_hours_to_standard(h, 'factual')
      end
      hours.flatten!

      profile_attributes = {
        business_location_attributes: {
          name: row[1],
          address: row[2],
          city: row[5],
          state: row[6],
          zip: row[9],
          email: row[17],
          phone: row[11],
          hours: hours,
          latitude: row[13],
          longitude: row[14]
        },
        content_attributes: {
          title: row[1],
          pubdate: Time.zone.now
        },
        existence: row[24].strip.to_f,
        source: 'Factual',
        source_id: row[0],
        business_category_ids: subtext_category_ids
      }

      # check for existing organizations since we want multiple business profiles
      # for one org to use the same one. And we index organization_name uniqueness...
      if org=Organization.find_by_name(row[1].strip)
        profile_attributes[:content_attributes][:organization_id] = org.id
      else
        profile_attributes[:content_attributes][:organization_attributes] = {
          name: row[1].strip,
          website: row[16].strip
        }
      end

      # we're going to be re-running this, so we need to identify if the profile already exists
      if existing_profile.present?
        existing_attrs = {
          id: existing_profile.id,
          content_attributes: {
            id: existing_profile.content.id,
            organization_attributes: { 
              id: existing_profile.content.organization.id
            }
          },
          business_location_attributes: {
            id: existing_profile.business_location.id
          }
        }

        if existing_profile.update_attributes(profile_attributes.deep_merge(existing_attrs))
          puts "Updated existing business profile ID #{existing_profile.id}\n"
        else
          puts "Error updating business profile #{existing_profile.id}:\n #{existing_profile.errors.messages}\n"
        end
      else
        bp = BusinessProfile.create(profile_attributes)
        if bp.id
          puts "Created new business profile (ID: #{bp.id}) from Factual:#{row[0]}"
        else
          puts "Error creating Factual:#{row[0]}:\n #{bp.errors.messages}\n"
        end
      end
    end
  end

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
