class AddOptionsToFeatures < ActiveRecord::Migration
  def change
    add_column :features, :options, :text
  end
end
