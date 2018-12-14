# frozen_string_literal: true

class AddCalendarCardActiveToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :calendar_card_active, :boolean, default: false
  end
end
