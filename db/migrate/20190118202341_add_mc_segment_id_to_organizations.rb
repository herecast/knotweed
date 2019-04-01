# frozen_string_literal: true

class AddMcSegmentIdToOrganizations < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :mc_segment_id, :string
  end
end
