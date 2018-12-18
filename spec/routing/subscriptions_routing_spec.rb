# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubscriptionsController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/admin/subscriptions').to route_to('subscriptions#index')
    end

    it 'routes to #new' do
      expect(get: '/admin/subscriptions/new').to route_to('subscriptions#new')
    end

    it 'routes to #show' do
      expect(get: '/admin/subscriptions/1').to route_to('subscriptions#show', id: '1')
    end

    it 'routes to #edit' do
      expect(get: '/admin/subscriptions/1/edit').to route_to('subscriptions#edit', id: '1')
    end

    it 'routes to #create' do
      expect(post: '/admin/subscriptions').to route_to('subscriptions#create')
    end

    it 'routes to #update via PUT' do
      expect(put: '/admin/subscriptions/1').to route_to('subscriptions#update', id: '1')
    end

    it 'routes to #update via PATCH' do
      expect(patch: '/admin/subscriptions/1').to route_to('subscriptions#update', id: '1')
    end

    it 'routes to #destroy' do
      expect(delete: '/admin/subscriptions/1').to route_to('subscriptions#destroy', id: '1')
    end
  end
end
