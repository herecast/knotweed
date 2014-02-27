class AddJsonResponseToAnnotationReports < ActiveRecord::Migration
  def change
    add_column :annotation_reports, :json_response, :text
  end
end
