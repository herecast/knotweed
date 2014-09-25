class AddCategoryReviewedToContents < ActiveRecord::Migration
  def change
    add_column :contents, :category_reviewed, :boolean, default: false
  end
end
