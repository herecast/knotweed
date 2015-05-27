# This migration comes from front_end_builds (originally 20150124215337)
class CreateFrontEndBuildsPubkeys < ActiveRecord::Migration
  def change
    create_table :front_end_builds_pubkeys do |t|
      t.string :name, null: false
      t.text :pubkey, null: false

      t.timestamps null: false
    end
  end
end
