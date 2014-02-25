class CreateAnnotationReports < ActiveRecord::Migration
  def change
    create_table :annotation_reports do |t|
      t.integer :content_id

      t.timestamps
    end
  end
end
