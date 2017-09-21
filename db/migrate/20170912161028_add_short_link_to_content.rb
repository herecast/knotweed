class AddShortLinkToContent < ActiveRecord::Migration
  def change
    add_column :contents, :short_link, :string
  end
end
