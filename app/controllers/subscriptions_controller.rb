class SubscriptionsController < ApplicationController
  before_action :set_subscription, only: [:show, :edit, :update, :destroy]
  before_action :store_query_in_session, only: [:index]

  def index
    @search = Subscription.ransack(search_query)
    @subscriptions = @search.result(distinct: true)\
      .active\
      .includes(:listserv)\
      .order("created_at DESC")\
      .page(params[:page])
  end

  def show
  end

  def new
    @subscription = Subscription.new
  end

  def edit
  end

  def create
    @subscription = Subscription.new(subscription_params)

    if @subscription.save
      redirect_to subscriptions_url, notice: 'Subscription was successfully created.'
    else
      render action: 'new'
    end
  end

  def update
    if @subscription.update(subscription_params)
      redirect_to subscriptions_url, notice: 'Subscription was successfully updated.'
    else
      render action: 'edit'
    end
  end

  def destroy
    @subscription.destroy
    redirect_to subscriptions_url
  end

  private
    def set_subscription
      @subscription = Subscription.find(params[:id])
    end

    def subscription_params
      params.require(:subscription).permit(
        :email, :listserv_id, :blacklist, :source, :unsubscribed_at,
        :confirmed_at, :user_id)
    end

    def store_query_in_session
      if params[:q].present?
        session[:subscriptions_search] = params[:q]
      end
    end

    def search_query
      session[:subscriptions_search] || params[:q]
    end
end
