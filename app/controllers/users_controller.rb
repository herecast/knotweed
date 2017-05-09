class UsersController < ApplicationController

  def index
    authorize! :index, @user, :message => 'Not authorized as an administrator.'
    @user_sources = User.pluck(:source).compact.uniq

    if params[:reset]
      session[:users_search] = { archived_true: false }
    elsif params[:q].present?
      session[:users_search] = params[:q]
    end

    @search = User.ransack(session[:users_search])
    @search.sorts = 'created_at desc'
    @users = @search.result(distinct: true).page(params[:page]).per(25)
  end

  def show
    @user = User.find(params[:id])
  end

  def edit
    @user = User.find(params[:id])
    @organizations = Organization.with_role(:manager, @user)
    @digests = Listserv.all
  end

  def update
    @user = User.find(params[:id])
    authorize! :update, @user, :message => 'Not authorized as an administrator.'
    @user.skip_reconfirmation!
    params[:user].delete(:password) if params[:user][:password].blank?
    if @user.update_attributes(user_params)
      process_user_roles
      process_user_organizations
      redirect_to @user, :notice => "User updated."
    else
      @digests = Listserv.all
      @organizations = Organization.with_role(:manager, @user)
      render action: 'edit', :alert => "Unable to update user."
    end
  end

  def update_subscription
    @user = User.find_by id: params[:user_id]
    if params['listserv_id'].to_i.in?(@user.active_listserv_subscription_ids)
      sub = @user.subscriptions.where(listserv_id: params['listserv_id'].to_i).first
      UnsubscribeSubscription.call(sub)
      render nothing: true, status: 200
    else
      listserv = Listserv.find(params['listserv_id'])
      SubscribeToListservSilently.call(listserv, @user, request.remote_ip)
      render nothing: true, status: 200
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
      new_params = params.require(:user).permit(:name, :email, :password,
        :location_id, :archived, roles: [:admin,:event_manager,:blogger])
      if new_params[:roles].present?
        new_params[:role_ids] = []
        new_params[:roles].each do |k,v|
          new_params[:role_ids] << Role.get(k.to_s).id if v == 'on'
        end
        new_params.delete :roles
      end
      new_params
    end

    def process_user_roles
      if params[:user].has_key? :roles
        @user.roles.clear
        ['admin', 'event_manager', 'blogger'].each do |role|
          if params[:user][:roles][role].present? and params[:user][:roles][role] == 'on'
            @user.roles << Role.find_by(name: role)
          end
        end
      end
    end

    def process_user_organizations
      params[:user].each do |key, value|
        @user.add_role :manager, Organization.find_by(id: value) if key.include?('controlled_organization')
      end
    end

    def new_subscription_ids
      if params['listserv_id'].present?
        new_subs =  params['listserv_id'].to_i - @user.subscriptions.map(&:listserv_id)
        new_subs.map!(&:to_i)
      end
    end

end
