# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UsersController, type: :routing do
  describe 'routing' do
    it 'routes to #create' do
      expect(post: '/admin/users/admin-create').to route_to('users#create')
    end

    it 'routes to #update' do
      expect(put: '/admin/users/1/admin-update').to route_to('users#update', id: '1')
    end
  end
end
