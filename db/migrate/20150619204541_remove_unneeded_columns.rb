class RemoveUnneededColumns < ActiveRecord::Migration
  def up
    remove_column :contents, :cost
    remove_column :contents, :start_date
    remove_column :contents, :end_date
    remove_column :contents, :recurrence
    remove_column :contents, :event_type
    remove_column :contents, :event_title
    remove_column :contents, :event_description
    remove_column :contents, :event_url
    remove_column :contents, :sponsor_url
    remove_column :contents, :processed_content
    remove_column :contents, :featured
    remove_column :contents, :business_location_id
    remove_column :contents, :host_organization
    remove_column :contents, :links
    remove_column :contents, :summary
    remove_column :contents, :mimetype
    remove_column :contents, :wordcount
    remove_column :contents, :file

    remove_column :events, :contact_url

    remove_column :users, :view_style
    remove_column :users, :event_poster
    remove_column :users, :discussion_listserve
  end

  def down
    add_column :contents, :cost, :string
    add_column :contents, :start_date, :datetime
    add_column :contents, :end_date, :datetime
    add_column :contents, :recurrence, :string 
    add_column :contents, :event_type, :string
    add_column :contents, :event_title, :string
    add_column :contents, :event_description, :text
    add_column :contents, :event_url, :string
    add_column :contents, :sponsor_url, :string
    add_column :contents, :processed_content, :text
    add_column :contents, :featured, :boolean
    add_column :contents, :business_location_id, :integer
    add_column :contents, :host_organization, :string
    add_column :contents, :links, :text
    add_column :contents, :summary, :text
    add_column :contents, :mimetype, :string
    add_column :contents, :wordcount, :string
    add_column :contents, :file, :string

    add_column :events, :contact_url, :string

    #add_column :users, :view_style, :integer
    add_column :users, :event_poster, :boolean
    add_column :users, :discussion_listserve, :string
  end

end
