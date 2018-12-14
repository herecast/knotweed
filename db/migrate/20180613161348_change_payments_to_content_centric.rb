# frozen_string_literal: true

class ChangePaymentsToContentCentric < ActiveRecord::Migration
  def change
    remove_column :payments, :user_id, :integer
    add_reference :payments, :content, foreign_key: true
  end
end
