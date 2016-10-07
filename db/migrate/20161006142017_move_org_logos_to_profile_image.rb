class MoveOrgLogosToProfileImage < ActiveRecord::Migration
  def up
    publishers = Organization.where(can_publish_news: true)
    publishers.each do |p|
      begin
        p.update_attribute(:remote_profile_image_url, p.logo.url) if p.logo?
        p.remove_logo!
        p.save
      rescue Exception => e
        puts "For Organization: #{p.name} the logo change failed with: #{e.inspect}"
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
