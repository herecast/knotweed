class UsersController < ApplicationController

  def index
    authorize! :index, @user, :message => 'Not authorized as an administrator.'

    if params[:reset]
      session[:users_search] = nil
    elsif params[:q].present?
      session[:users_search] = params[:q]
    end

    @search = User.ransack(session[:users_search])
    @users = @search.result(distinct: true).page(params[:page]).per(25)
  end

  def show
    @user = User.find(params[:id])
  end

  def edit
    @user = User.find_by id: params[:id]
    @organizations = Organization.with_role(:manager, @user)
  end

  def update
    @user = User.find(params[:id])
    authorize! :update, @user, :message => 'Not authorized as an administrator.'
    @user.roles.clear
    params[:user].delete(:password) if params[:user][:password].blank?
    if @user.update_attributes(user_params)
      process_user_roles
      process_user_organizations
      redirect_to @user, :notice => "User updated."
    else
      redirect_to @user, :alert => "Unable to update user."
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
    @user = User.new(user_params)
    authorize! :create, @user
    process_user_roles
    process_user_organizations
    if @user.save!
      flash[:notice] = "User created."
      redirect_to @user
    else
      flash.now[:alert] = "There was a problem creating the user"
      render "new"
    end
  end

  private

    def user_params
      params.require(:user).permit(:name, :email, :password, :location_id)
    end

    def process_user_roles
      ['admin', 'event_manager', 'blogger'].each do |role|
        if params[:user][role].present? and params[:user][role] == 'on'
          @user.roles << Role.find_by(name: role)
        end
      end
    end

    def process_user_organizations
      params[:user].each do |key, value|
        @user.add_role :manager, Organization.find_by(id: value) if key.include?('controlled_organization')
      end
    end

end
