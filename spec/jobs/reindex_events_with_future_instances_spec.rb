# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReindexEventsWithFutureInstances, type: :job do
  describe '#perform', elasticsearch: true do
    subject { ReindexEventsWithFutureInstances.perform_now }

    context 'when Event has no future event instances' do
      before do
        @event = FactoryGirl.create :content, :event,
                                    has_future_event_instance: nil
        @event.channel.event_instances[0].update_attribute(
          :start_date, 1.week.ago
        )
      end

      it 'sets has_future_event_instance to false' do
        expect { subject }.to change {
          @event.reload.has_future_event_instance
        }.to false
      end
    end

    context 'when Event has future instance' do
      before do
        @event = FactoryGirl.create :content, :event,
                                    has_future_event_instance: nil
        @event.channel.event_instances.create(start_date: 1.month.from_now)
        @event.reindex
      end

      it 'reindexes event to push starts_at forward' do
        expect(
          Content.search('*',
                         load: false, where: { id: @event.id })[0].starts_at[0..9]
        ).to eq @event.channel.event_instances[0].start_date.to_s[0..9]

        Timecop.travel(2.weeks.from_now)
        subject

        expect(
          Content.search('*',
                         load: false, where: { id: @event.id })[0].starts_at[0..9]
        ).to eq @event.channel.event_instances[1].start_date.to_s[0..9]
        Timecop.return
      end
    end
  end
end
