class DropBusinessFeedbacksTable < ActiveRecord::Migration[5.1]
  def change
    drop_table :business_feedbacks
  end
end
