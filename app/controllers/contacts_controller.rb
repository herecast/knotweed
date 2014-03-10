class ContactsController < ApplicationController
  load_and_authorize_resource

  def edit
    respond_to do |format|
      format.js { render partial: "contacts/form" }
    end
  end

  def new
    if params[:model].present? and params[:id].present?
      # need to revisit this for security, at least validate that "model" is in fact just a model
      eval("@#{params[:model].downcase.underscore} = #{params[:model]}.find(#{params[:id]})")
    end
    render partial: "contacts/form", layout: false 
  end

  def create
    @contact.save!
    respond_to do |format|
      format.js
    end
  end

  def update
    @contact.update_attributes!(params[:contact])
    respond_to do |format|
      format.js
    end
  end

  def destroy
    @contact.destroy
    respond_to do |format|
      format.js
    end
  end

end
