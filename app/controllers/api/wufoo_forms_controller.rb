class Api::WufooFormsController < Api::ApiController
  def index
    @wufoo_forms = WufooForm.active

    if params[:wufoo_forms].present?
      @wufoo_forms = @wufoo_forms.where(controller: params[:wufoo_forms][:controller]) if params[:wufoo_forms][:controller].present?
      @wufoo_forms = @wufoo_forms.where(action: params[:wufoo_forms][:action]) if params[:wufoo_forms][:action].present?
    end
    render json: @wufoo_forms
  end

  def show
    @wufoo_form = WufooForm.find(params[:id])
    render json: @wufoo_form
  end
end
