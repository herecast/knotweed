class CreateRepositories < ActiveRecord::Migration
  def change
    create_table :repositories do |t|
      t.string :name
      t.string :dsp_endpoint
      t.string :sesame_endpoint

      t.timestamps
    end

    add_column :annotation_reports, :repository_id, :integer
    remove_column :contents, :published
  end
end
