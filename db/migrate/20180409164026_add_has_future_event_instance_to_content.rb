# frozen_string_literal: true

class AddHasFutureEventInstanceToContent < ActiveRecord::Migration
  def change
    add_column :contents, :has_future_event_instance, :boolean
  end
end
