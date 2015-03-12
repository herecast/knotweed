class AddChannelTypeAndChannelIdToContents < ActiveRecord::Migration
  def up
    add_column :contents, :channel_type, :string
    add_column :contents, :channel_id, :integer
    add_index :contents, :channel_type
    add_index :contents, :channel_id

    # best to migrate data with a SQL query here
    # because otherwise, we're going to be doing a separate retrieval
    # and update call for every single event/content pair
    Content.joins("inner join events on events.content_id = contents.id")
      .update_all("channel_type = 'Event', channel_id = events.id")

    remove_column :events, :content_id
    remove_column :contents, :channelized
  end

  def down
    add_column :events, :content_id, :integer
    add_column :contents, :channelized, :boolean

    Content.where("channel_id IS NOT NULL").update_all("channelized = 1")
    Event.joins("inner join contents on contents.channel_id = events.id")
      .where("contents.channel_type = 'Event'")
      .update_all("events.content_id = contents.channel_id")

    remove_column :contents, :channel_type
    remove_column :contents, :channel_id
  end
end
