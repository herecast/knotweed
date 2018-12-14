# frozen_string_literal: true

class AddActiveToContentCategory < ActiveRecord::Migration
  def change
    add_column :content_categories, :active, :boolean, default: true
  end
end
