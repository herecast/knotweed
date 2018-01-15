class DefaultEmptyHashForLinkClicks < ActiveRecord::Migration
  def change
    change_column :listserv_digests, :link_clicks, :hstore, default: '', null: false
  end
end
