# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'EventInstance::ActiveDates endpoints', type: :request do
  describe '/event_instances/active_dates', elasticsearch: true do
    context 'Given instances in in different days, in future' do
      before do
        FactoryGirl.create(:event_instance, start_date: 1.day.from_now)

        FactoryGirl.create_list(:event_instance, 3,
                                start_date: 3.days.from_now)
      end

      subject do
        get '/api/v3/event_instances/active_dates'
      end

      it 'returns the dates and count of events corresponding' do
        subject
        expect(response.body).to include_json(
          active_dates: [
            {
              date: 1.day.from_now.strftime('%Y-%m-%d'),
              count: 1
            },
            {
              date: 3.days.from_now.strftime('%Y-%m-%d'),
              count: 3
            }
          ]
        )
      end
    end

    describe 'filtering by date range' do
      let(:start_date) do
        1.day.ago.to_date
      end

      let(:end_date) do
        1.day.from_now.to_date
      end

      subject do
        get '/api/v3/event_instances/active_dates', params: {
          start_date: start_date,
          end_date: end_date
        }
      end

      let!(:instance_within_range) { FactoryGirl.create :event_instance, start_date: Date.current }

      let!(:instance_out_of_range) { FactoryGirl.create :event_instance, start_date: 3.days.from_now }

      it 'returns only data for range' do
        subject
        expect(response.body).to eql({ active_dates: [
          {
            date: Date.current,
            count: 1
          }
        ] }.to_json)
      end
    end
  end
end