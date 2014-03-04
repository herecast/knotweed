class MakeJsonResponseLongTextOnAnnotationReports < ActiveRecord::Migration
  def up
    change_column :annotation_reports, :json_response, :longtext

    AnnotationReport.where("json_response IS NOT NULL").each do |ar|
      begin
        json_data = JSON.parse(Admin::OntotextController.get_annotations(ar.content.id))["results"]["bindings"][0]["annotation"]["value"]
        ar.update_attribute :json_response, json_data
        puts "updated json for ar #{ar.id}"
      rescue
        puts "could not update json for ar #{ar.id}"
      end
    end
  end

  def down
    change_column :annotation_reports, :json_response, :text
  end

end
