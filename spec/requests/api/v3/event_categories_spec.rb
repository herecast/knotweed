require 'spec_helper'

RSpec.describe 'Event Categories Endpoint', type: :request do

  describe 'GET /api/v3/event_categories' do
    before do
      @event_category = FactoryGirl.create :event_category
    end

    subject { get '/api/v3/event_categories' }

    it "returns event categories" do
      subject
      expect(response.body).to include_json({
        event_categories: [{
          id: @event_category.id,
          name: @event_category.name,
          slug: @event_category.slug
        }]
      })
    end
  end
end