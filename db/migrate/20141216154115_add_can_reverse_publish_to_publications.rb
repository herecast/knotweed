class AddCanReversePublishToPublications < ActiveRecord::Migration
  def change
    add_column :publications, :can_reverse_publish, :boolean, default: false
  end
end
