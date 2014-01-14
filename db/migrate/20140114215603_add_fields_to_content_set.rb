class AddFieldsToContentSet < ActiveRecord::Migration
  def change
    add_column :content_sets, :start_date, :date
    add_column :content_sets, :end_date, :date
    add_column :content_sets, :ongoing, :boolean
    add_column :content_sets, :format, :string
  end
end
