class AddReversePublishEmailToPublication < ActiveRecord::Migration
  def change
    add_column :publications, :reverse_publish_email, :string
  end
end
