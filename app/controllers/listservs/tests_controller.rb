module Admin
  class Listservs::TestsController < ApplicationController

    def create
      listserv = Listserv.find(params[:listserv_id])
      digest = Outreach::BuildDigest.call(listserv)
      if digest.save
        BackgroundJob.perform_later('Outreach::TestDigest', 'call', {user: current_user, digest: digest})
        flash[:notice] = 'A test digest will be on its way to you within 10 minutes'
        redirect_to listservs_path
      else
        flash[:warning] = 'Problem testing listserv'
        redirect_to listservs_path
      end
    end
  end
end