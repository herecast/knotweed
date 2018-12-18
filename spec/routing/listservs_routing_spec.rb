# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ListservsController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/admin/listservs').to route_to('listservs#index')
    end

    it 'routes to #new' do
      expect(get: '/admin/listservs/new').to route_to('listservs#new')
    end

    it 'routes to #show' do
      expect(get: '/admin/listservs/1').to route_to('listservs#show', id: '1')
    end

    it 'routes to #edit' do
      expect(get: '/admin/listservs/1/edit').to route_to('listservs#edit', id: '1')
    end

    it 'routes to #create' do
      expect(post: '/admin/listservs').to route_to('listservs#create')
    end

    it 'routes to #update via PUT' do
      expect(put: '/admin/listservs/1').to route_to('listservs#update', id: '1')
    end

    it 'routes to #update via PATCH' do
      expect(patch: '/admin/listservs/1').to route_to('listservs#update', id: '1')
    end

    it 'routes to #destroy' do
      expect(delete: '/admin/listservs/1').to route_to('listservs#destroy', id: '1')
    end
  end
end
