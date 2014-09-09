class WufooFormsController < ApplicationController
  load_and_authorize_resource
  def index
  end

  def new
  end

  def create
    if @wufoo_form.save
      flash[:notice] = "Form saved."
      redirect_to wufoo_forms_path
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    @wufoo_form = WufooForm.find(params[:id])
    if @wufoo_form.update_attributes(params[:wufoo_form])
      flash[:notice] = "Form updated."
      redirect_to wufoo_forms_path
    else
      render 'edit'
    end
  end

  def destroy
  end
end
