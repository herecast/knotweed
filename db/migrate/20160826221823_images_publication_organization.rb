class ImagesPublicationOrganization < ActiveRecord::Migration
  def up
    Image.where(imageable_type: 'Publication').update_all(imageable_type: 'Organization')
  end

  def down
  end
end
