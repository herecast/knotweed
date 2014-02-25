class CreateAnnotations < ActiveRecord::Migration
  def change
    create_table :annotations do |t|
      t.integer :annotation_report_id
      t.string :annotation_id
      t.boolean :accepted

      t.timestamps
    end
  end
end
