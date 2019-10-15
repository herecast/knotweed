# frozen_string_literal: true

class UsersController < ApplicationController
  def index
    authorize! :index, @user, message: 'Not authorized as an administrator.'
    @user_sources = User.pluck(:source).compact.uniq

    if params[:reset]
      session[:users_search] = { archived_true: false }
    elsif params[:q].present?
      session[:users_search] = params[:q]
    end

    if session[:users_search].try(:[], :roles).present?
      role_ids = []
      session[:users_search][:roles].each do |key, value|
        role_ids << Role.get(key.to_s).id if value == 'on'
      end
      scope = User.joins(:roles).where(roles: { id: role_ids })
    else
      scope = User
    end

    if display_social_users?
      social_user_ids = SocialLogin.pluck(:user_id)
      @search = scope.ransack(id_in: social_user_ids)
      @total_count = SocialLogin.count
    else
      @search = scope.ransack(session[:users_search])
    end

    @search.sorts = 'created_at desc'
    @total_count = @search.result.count

    @page = if params[:page].nil?
              1
            else
              params[:page].to_i
            end
    @users = @search.result.page(params[:page]).per(25)
  end

  def show
    @user = User.find(params[:id])
  end

  def edit
    @user = User.find(params[:id])
    @digests = Listserv.all
  end

  def update
    @user = User.find(params[:id])
    authorize! :update, @user, message: 'Not authorized as an administrator.'
    @user.skip_reconfirmation!
    params[:user].delete(:password) if params[:user][:password].blank?
    if @user.update_attributes(user_params)
      process_user_organizations
      redirect_to @user, notice: 'User updated.'
    else
      @digests = Listserv.all
      @organizations = Organization.with_role(:manager, @user)
      render action: 'edit', alert: 'Unable to update user.'
    end
  end

  def update_subscription
    @user = User.find_by id: params[:user_id]
    if params['listserv_id'].to_i.in?(@user.active_listserv_subscription_ids)
      sub = @user.subscriptions.where(listserv_id: params['listserv_id'].to_i).first
      UnsubscribeSubscription.call(sub)
      head :no_content, status: 200
    else
      listserv = Listserv.find(params['listserv_id'])
      SubscribeToListservSilently.call(listserv, @user, request.remote_ip)
      head :no_content, status: 200
    end
  end

  def destroy
    authorize! :destroy, @user, message: 'Not authorized as an administrator.'
    user = User.find(params[:id])
    if user == current_user
      redirect_to users_path, notice: "Can't delete yourself."
    else
      user.destroy
      redirect_to users_path, notice: 'User deleted.'
    end
  end

  def new
    @user = User.new
    @digests = Listserv.active
    authorize! :new, @user
  end

  def create
    @user = User.new(user_params)
    authorize! :create, @user
    process_user_organizations
    if @user.save
      flash[:notice] = 'User created.'
      redirect_to @user
    else
      flash.now[:alert] = 'There was a problem creating the user'
      render 'new'
    end
  end

  private

  def user_params
    params.require(:user).permit(
      :name,
      :email,
      :password,
      :location_confirmed,
      :location_id,
      :archived,
      :receive_comment_alerts,
      :fullname,
      :nickname,
      :epayment,
      :w9,
      :handle
    ).tap do |attrs|
      attrs[:role_ids] = []
      if params[:user][:roles].present?
        params[:user][:roles].each do |key, value|
          attrs[:role_ids] << Role.get(key.to_s).id if value == 'on'
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
      new_subs = params['listserv_id'].to_i - @user.subscriptions.map(&:listserv_id)
      new_subs.map!(&:to_i)
    end
  end

  def display_social_users?
    params[:q].present? && params[:q][:social_login] == '1'
  end
end
