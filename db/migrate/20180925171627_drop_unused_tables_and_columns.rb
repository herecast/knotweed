# frozen_string_literal: true

class DropUnusedTablesAndColumns < ActiveRecord::Migration
  def up
    drop_table :category_corrections
    drop_table :content_promotion_banner_loads
    drop_table :issues
    drop_table :notifiers
    drop_table :channels
    drop_table :categories
    remove_column :contents, :category_reviewed
    remove_column :contents, :issue_id
    remove_column :users, :default_repository_id
    remove_column :contents, :source_category
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
