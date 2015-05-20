class AddSocialEnabledToEvents < ActiveRecord::Migration
  def change
    add_column :events, :social_enabled, :boolean, default: false
  end
end
