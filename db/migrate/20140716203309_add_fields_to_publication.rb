class AddFieldsToPublication < ActiveRecord::Migration
  def change
    add_column :publications, :tagline, :text
    add_column :publications, :links, :text
    add_column :publications, :social_media, :text
    add_column :publications, :general, :text
    add_column :publications, :header, :text
  end
end
