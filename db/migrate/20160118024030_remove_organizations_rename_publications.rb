class RemoveOrganizationsRenamePublications < ActiveRecord::Migration
  def up
    # FIRST, rename the old organizatinos table so we can rename publications to organizations
    rename_table :organizations, :old_organizations
    rename_column :publications, :pub_type, :org_type
    rename_table :publications, :organizations

    # remove unused columns while we're on the topic
    remove_column :organizations, :publishing_frequency
    remove_column :organizations, :tagline
    remove_column :organizations, :links
    remove_column :organizations, :social_media
    remove_column :organizations, :general
    remove_column :organizations, :header

    # all 'organizations' came from publication model, so we want to set them appropriately.
    Organization.update_all 'org_type = "publication"'

    rename_table :consumer_apps_publications, :consumer_apps_organizations
    rename_column :consumer_apps_organizations, :publication_id, :organization_id

    rename_table :content_categories_publications, :content_categories_organizations
    rename_column :content_categories_organizations, :publication_id, :organization_id

    rename_column :content_sets, :publication_id, :organization_id
    
    rename_column :contents, :publication_id, :organization_id

    rename_column :issues, :publication_id, :organization_id

    rename_table :locations_publications, :locations_organizations
    rename_column :locations_organizations, :publication_id, :organization_id

    rename_column :promotions, :publication_id, :organization_id

    # converting pubs/bls to a habtm is going to be a new migration later as
    # it really isn't part of this functional change.
    rename_column :business_locations, :publication_id, :organization_id

    # interestingly, this table existed and wasn't *completely* empty, but according to the code,
    # wasn't really used, so I'm just removing it rather than trying to translate.
    drop_table :contacts_publications

    # convert existing OldOrganizations to the new Organization model (aka the old Publication model)
    OldOrganization.all.each do |org|
      if existing_pub=Organization.find_by_name(org.name)
        say "there was already a publication with this name: #{org.name} with id: #{existing_pub.id}. Skipping..."
      else # no matching pub, so easy to just create a new organization
        new_org = Organization.new({
          org_type: org.org_type,
          notes: org.notes,
          logo: org.logo,
        })
        new_org.contacts = org.contacts
        new_org.children = org.children
        new_org.users = org.users
        new_org.parsers = org.parsers
        new_org.import_jobs = org.import_jobs
        new_org.save!
      end
    end

    drop_table :old_organizations
  end

  def down
    create_table :old_organizations do |t|
      t.string   "name"
      t.string   "org_type"
      t.text     "notes"
      t.string   "tagline"
      t.text     "links"
      t.text     "social_media"
      t.text     "general"
      t.string   "header"
      t.string   "logo"
      t.timestamps
    end

    Organization.where('org_type != "publication"').each do |o|
      org = OldOrganization.new({
        name: o.name,
        org_type: o.org_type,
        logo: o.logo
      }) # note, other fields are lost permanently as the task
      # called for removing them.
      org.contacts = o.contacts
      org.users = o.users
      org.organizations = o.children
      org.parsers = o.parsers
      org.import_jobs = o.import_jobs
      org.save!
    end

    rename_table :organizations, :publications
    rename_table :old_organizations, :organizations

    rename_column :publications, :org_type, :pub_type
    add_column :publications, :publishing_frequency, :string
    add_column :publications, :tagline, :string
    add_column :publications, :links, :text
    add_column :publications, :social_media, :text
    add_column :publications, :general, :text
    add_column :publications, :header, :string

    rename_column :consumer_apps_organizations, :organization_id, :publication_id
    rename_table :consumer_apps_organizations, :consumer_apps_publications

    rename_column :content_categories_organizations, :organization_id, :publication_id
    rename_table :content_categories_organizations, :content_categories_publications

    rename_column :content_sets, :organization_id, :publication_id

    rename_column :contents, :organization_id, :publication_id

    rename_column :issues, :organization_id, :publication_id

    rename_column :locations_organizations, :organization_id, :publication_id
    rename_table :locations_organizations, :locations_publications

    rename_column :promotions, :organization_id, :publication_id

    rename_column :business_locations, :organization_id, :publication_id

    create_table :contacts_publications, id: false do |t|
      t.integer :publication_id
      t.integer :contact_id
    end
  end
end

class OldOrganization < ActiveRecord::Base
  has_and_belongs_to_many :contacts, join_table: 'contacts_organizations', foreign_key: 'organization_id'
  has_many :organizations, foreign_key: 'organization_id' # this is the ownership relationship over publications
  has_many :users, foreign_key: 'organization_id'
  has_many :parsers, foreign_key: 'organization_id'
  has_many :import_jobs, foreign_key: 'organization_id'

  attr_accessible :name, :org_type, :notes, :general, :tagline, :header, :header_cache,
                  :remove_header, :logo, :logo_cache, :removeLogo

  mount_uploader :header, ImageUploader
  mount_uploader :logo, ImageUploader

  serialize :general, Hash

  ORG_TYPE_OPTIONS = ["Ad Agency", "Business", "Community", "Educational", "Government", "Publisher"]

  validates_presence_of :name
  validates :org_type, inclusion: { in: ORG_TYPE_OPTIONS }, allow_blank: true

  def org_type_enum
    ORG_TYPE_OPTIONS
  end
end
