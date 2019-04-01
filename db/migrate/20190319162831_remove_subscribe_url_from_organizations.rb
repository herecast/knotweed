# frozen_string_literal: true

class RemoveSubscribeUrlFromOrganizations < ActiveRecord::Migration[5.1]
  def change
    remove_column :organizations, :subscribe_url, :string
  end
end
