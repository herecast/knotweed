class CreatePublishJobs < ActiveRecord::Migration
  def change
    create_table :publish_jobs do |t|
      t.text :query_params
      t.integer :organization_id
      t.string :status
      t.integer :frequency, default: 0
      t.string :publish_method
      t.boolean :archive, default: false
      t.string :error
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
