class AddPublishingFrequencyToContentSets < ActiveRecord::Migration
  def change
    add_column :content_sets, :publishing_frequency, :string
  end
end
