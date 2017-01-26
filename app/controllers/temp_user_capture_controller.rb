class TempUserCaptureController < ApplicationController
  before_action :set_temp_user, only: [:show, :destroy]

  def index
    @temp_users = TempUserCapture.all
  end

  def destroy
    @temp_user.destroy
    redirect_to temp_users_path
  end

  private

  def set_temp_user
    @temp_user = TempUserCapture.find(params[:id])
  end
end
