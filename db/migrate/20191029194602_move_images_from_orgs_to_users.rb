class MoveImagesFromOrgsToUsers < ActiveRecord::Migration[5.1]
  def up
    Organization.where.not(user_id: nil).each do |organization|
      user = organization.user
      user_updates = {}

      if organization.name.present? && user.name.blank?
        user_updates[:name] = organization.name
      end

      if organization.website.present? && user.website.blank?
        user_updates[:website] = organization.website
      end

      if organization.description.present? && user.description.blank?
        user_updates[:description] = organization.description
      end

      user.update_attributes(user_updates)

      if organization.profile_image_url.present? && user.avatar_url.blank?
        begin
          organization.profile_image.cache_stored_file!
          file = File.open(organization.profile_image.full_cache_path)
          user.avatar = file
          user.save
        rescue
          puts "Issue moving #{organization.name}, id: #{organization.id}, profile image to User id: #{user.id}"
        end
      end

      if organization.background_image_url.present? && user.background_image_url.blank?
        begin
          organization.background_image.cache_stored_file!
          file = File.open(organization.background_image.full_cache_path)
          user.background_image = file
          user.save
        rescue
          puts "Issue moving #{organization.name}, id: #{organization.id}, background image to User id: #{user.id}"
        end
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
