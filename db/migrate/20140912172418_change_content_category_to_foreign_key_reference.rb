class ChangeContentCategoryToForeignKeyReference < ActiveRecord::Migration
  def up
    add_column :contents, :content_category_id, :integer

    Content.find_each do |c|
      begin
        unless c.category.nil?
          content_category = ContentCategory.where(name: c.category).first_or_create 
          c.content_category = content_category
        end

        c.save!
      rescue => e
        Rails.logger.error("Error migrating content #{c.id}:\n#{e.backtrace.join("\n")}")
      end
    end

    remove_column :contents, :category
  end

  def down
    add_column :contents, :category, :string

    Content.find_each do |c|
      c.category = c.content_category.name
      c.save
    end

    remove_column :contents, :content_category_id
  end
end
