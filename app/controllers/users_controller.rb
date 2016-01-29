class UsersController < ApplicationController

  def index
    authorize! :index, @user, :message => 'Not authorized as an administrator.'
    @users = User.page(params[:page]).per(params[:limit])
  end

  def show
    @user = User.find(params[:id])
  end
  
  def update
    @user = User.find(params[:id])
    authorize! :update, @user, :message => 'Not authorized as an administrator.'
    if @user.update_attributes(params[:user], :as => :admin)
      redirect_to users_path, :notice => "User updated."
    else
      redirect_to users_path, :alert => "Unable to update user."
    end
  end
    
  def destroy
    authorize! :destroy, @user, :message => 'Not authorized as an administrator.'
    user = User.find(params[:id])
    unless user == current_user
      user.destroy
      redirect_to users_path, :notice => "User deleted."
    else
      redirect_to users_path, :notice => "Can't delete yourself."
    end
  end

  def new
    @user = User.new
    authorize! :new, @user
  end

  def create
    @user = User.new(params[:user])
    authorize! :create, @user
    if @user.save!
      flash[:notice] = "User created."
      redirect_to users_path
    else
      render "new"
    end
  end

end
