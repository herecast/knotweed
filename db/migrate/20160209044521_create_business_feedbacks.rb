class CreateBusinessFeedbacks < ActiveRecord::Migration
  def change
    create_table :business_feedbacks do |t|
      t.integer :created_by
      t.integer :updated_by
      t.integer :business_profile_id

      t.timestamps
    end
  end
end
