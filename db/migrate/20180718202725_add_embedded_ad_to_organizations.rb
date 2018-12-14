# frozen_string_literal: true

class AddEmbeddedAdToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :embedded_ad, :boolean, default: true
  end
end
