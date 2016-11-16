class FeaturesController < ApplicationController
  before_action :set_feature, only: [:show, :edit, :update]
  def index
    @features = Feature.all
  end

  def show
  end

  def new
    @feature = Feature.new
  end

  def edit
  end

  def create
    @feature = Feature.new(feature_params)

    if @feature.save
      redirect_to features_url, notice: 'Feature successfully created.'
    else
      render action: 'new'
    end
  end

  def update
    if @feature.update(feature_params)
      redirect_to features_url, notice: 'Feature successfully updated.'
    else
      render action: 'edit'
    end
  end


  private

  def set_feature
    @feature = Feature.find(params[:id])
  end

  def feature_params
    params.require(:feature).permit(
      :name,
      :description,
      :active,
      :expires_at
    )
  end

end
