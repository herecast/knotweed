class AddFieldsToAnnotationReports < ActiveRecord::Migration
  def change
    add_column :annotation_reports, :name, :string
    add_column :annotation_reports, :description, :text
  end
end
