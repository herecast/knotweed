class RemoveEventRelatedFieldsFromContents < ActiveRecord::Migration
  def up
    remove_column :contents, :event_description
    remove_column :contents, :event_title
    remove_column :contents, :start_date
    remove_column :contents, :end_date
    remove_column :contents, :sponsor_url
    remove_column :contents, :host_organization
    remove_column :contents, :event_url
    remove_column :contents, :business_location_id
    remove_column :contents, :featured
    remove_column :contents, :recurrence
    remove_column :contents, :cost
    remove_column :contents, :links
    remove_column :contents, :event_type
  end

  def down
    add_column :contents, :event_description, :text
    add_column :contents, :event_title, :string
    add_column :contents, :start_date, :datetime
    add_column :contents, :end_date, :datetime
    add_column :contents, :sponsor_url, :string
    add_column :contents, :host_organization, :string
    add_column :contents, :event_url, :string
    add_column :contents, :business_location_id, :integer
    add_column :contents, :featured, :boolean
    add_column :contents, :recurrence, :string
    add_column :contents, :cost, :string
    add_column :contents, :links, :text
    add_column :contents, :event_type, :string
  end
end
