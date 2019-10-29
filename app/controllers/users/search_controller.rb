# frozen_string_literal: true

class Users::SearchController < ApplicationController
  def index
    # always ignore archived users
    params[:q][:archived_true] = false
    @users = User.ransack(params[:q])
      .result.page(1).per(10) # max 10 results, we're not actually paging
    # context is passed via params to define the action button in the view
    render 'index', layout: false
  end
end
