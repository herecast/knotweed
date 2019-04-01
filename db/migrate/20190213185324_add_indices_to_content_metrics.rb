# frozen_string_literal: true

class AddIndicesToContentMetrics < ActiveRecord::Migration[5.1]
  def change
    add_index :content_metrics, :created_at
  end
end
