# frozen_string_literal: true

class RemoveUgcJobFromContents < ActiveRecord::Migration
  def up
    remove_column :contents, :ugc_job
  end

  def down
    add_coumn :contents, :ugc_job, :string
  end
end
