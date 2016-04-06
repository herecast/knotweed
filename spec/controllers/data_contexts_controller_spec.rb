require 'spec_helper'

describe DataContextsController do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  describe 'GET /data_contexts' do
    before do
      @data_context = FactoryGirl.create :data_context
    end
  end
end