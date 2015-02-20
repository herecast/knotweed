class AddChannelizedToContents < ActiveRecord::Migration
  def up
    add_column :contents, :channelized, :boolean, default: false
    add_index :contents, :channelized

    # data processing to update channelized for all existing contents
    Event.all.each do |e|
      e.content.update_attribute :channelized, true
    end
  end

  def down
    remove_index :contents, :channelized
    remove_column :contents, :channelized
  end
end
