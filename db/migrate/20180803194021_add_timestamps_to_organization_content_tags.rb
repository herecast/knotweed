class AddTimestampsToOrganizationContentTags < ActiveRecord::Migration
  def change
    add_timestamps :organization_content_tags
  end
end
