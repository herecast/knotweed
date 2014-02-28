class Admin::AnnotationReportsController < Admin::AdminController

  def create
    json_data = JSON.parse(Admin::OntotextController.get_annotations(params[:content_id]))["results"]["bindings"][0]["annotation"]["value"]
    @annotation_report = AnnotationReport.create(content_id: params[:content_id], name: params[:name], json_response: json_data)
    @hash_data = JSON.parse(json_data)
    @hash_data["annotation-sets"][0]["annotation"].each do |ant|
      new_ant = Annotation.new(annotation_report_id: @annotation_report.id, annotation_id: ant["id"], 
                                startnode: ant["startnode"], endnode: ant["endnode"], annotation_type: ant["type"])
      ant['feature-set'].each do |feature|
        val = feature["value"]["value"]
        case feature["name"]["name"]
        when "isGenerated"
          new_ant.is_generated = val
        when "string"
          new_ant.annotated_string = val
        when "class"
          new_ant.recognized_class = val
        when "inst"
          new_ant.instance = val
        when "originalClass"
          new_ant.lookup_class = val
        when "tokenFeature"
          new_ant.token_feature = val
        end
      end

      new_ant.save
      @annotation_report.annotations << new_ant
    end

    respond_to do |format|
      format.js { render "create" }
    end
  end

  def edit
    @annotation_report = AnnotationReport.find(params[:id])
    respond_to do |format|
      format.js { render "edit" }
    end
  end

  def table_row
    @annotation_report = AnnotationReport.find(params[:id])
    render partial: "admin/annotation_reports/partials/table_row", layout: false, locals: {ar: @annotation_report}
  end

end
