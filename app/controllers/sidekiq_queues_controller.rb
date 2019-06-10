# frozen_string_literal: true

class SidekiqQueuesController < ApplicationController
  skip_before_action :authorize_access!

  def show
    queue = params[:name] || 'default'
    render plain: Sidekiq::Queue.new(queue).size
  end
end