class Api::WufooFormsController < Api::ApiController
  def index
    @wufoo_forms = WufooForm.active

    if params[:wufoo_forms].present? and @wufoo_forms.present?
      @wufoo_forms = @wufoo_forms.where(controller: params[:wufoo_forms][:controller]) if params[:wufoo_forms][:controller].present?
      @wufoo_forms = @wufoo_forms.where(action: params[:wufoo_forms][:action]) if params[:wufoo_forms][:action].present?
    end

    @wufoo_forms = filter_active_record_relation_for_consumer_app(@wufoo_forms)
    render json: @wufoo_forms
  end

  def show
    if params[:id].present?
      @wufoo_form = WufooForm.find(params[:id])
    elsif params[:form_hash].present?
      @wufoo_form = WufooForm.find_by_form_hash(params[:form_hash])
    end
    if @wufoo_form.present?
      render json: @wufoo_form
    else
      render text: "No Wufoo form found.", status: 500
    end
  end
end
