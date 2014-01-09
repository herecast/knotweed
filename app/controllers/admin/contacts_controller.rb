class Admin::ContactsController < Admin::AdminController
  load_and_authorize_resource

  def edit
    respond_to do |format|
      format.js { render partial: "admin/contacts/form" }
    end
  end

  def new
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
