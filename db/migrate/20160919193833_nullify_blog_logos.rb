class NullifyBlogLogos < ActiveRecord::Migration
  def up
    blogs = Organization.where(org_type: 'Blog')
    blogs.each do |blog|
      begin
        blog.logo = nil
        blog.save validate: false
      rescue
        # catch issues with downloading image
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
