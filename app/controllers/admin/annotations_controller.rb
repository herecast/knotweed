class Admin::AnnotationsController < Admin::AdminController

  respond_to :js
  layout :false

  def edit
    @annotation = Annotation.where(annotation_report_id: params[:annotation_report_id], annotation_id: params[:annotation_id]).first
  end

  def accept_annotation
    @annotation = Annotation.find(params[:id])
    @annotation.update_attribute :accepted, params[:accepted]
    @annotation_report = @annotation.annotation_report
    @metrics = @annotation_report.metrics
  end

end