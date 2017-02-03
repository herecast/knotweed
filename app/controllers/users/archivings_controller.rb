class Users::ArchivingsController < ApplicationController
  def new
    @user = User.find params[:user_id]
    authorize! :update, @user, message: 'Not authorized to archive this user.'
  end

  def create
    @user = User.find params[:user_id]
    authorize! :update, @user, message: 'Not authorized to archive this user.'
    if params[:new_content_owner].present?
      new_owner = User.find_by(email: params[:new_content_owner])
      if new_owner.nil?
        flash.now[:error] = "The user account #{params[:new_content_owner]} could not be found."
        render 'new' and return
      end
    end

    if @user.update(archived: true)
      flash[:notice] = "User #{@user.email} has been archived."
      if new_owner.present?
        Content.where(created_by: @user).update_all(created_by: new_owner)
        flash[:notice] << " All content belonging to that account has been reassigned to #{new_owner.email}"
      end
      redirect_to users_path
    else
      flash.now[:error] = "There was a problem archiving the user"
      render 'new'
    end
  end
end
