class AddEventRelatedIndicesToContents < ActiveRecord::Migration
  def change
    add_index :contents, :start_date
    add_index :contents, :category
    add_index :contents, :end_date
  end
end
