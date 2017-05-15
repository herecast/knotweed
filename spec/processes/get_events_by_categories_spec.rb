require 'spec_helper'

RSpec.describe GetEventsByCategories do

  describe "::call", elasticsearch: true do

    context "when one category is passed" do
      before do
        @query = 'bar'
        @event_category = FactoryGirl.create :event_category, name: "Bars in Tatooine", query: @query
        @event = FactoryGirl.create :event, published: true
        @event.content.update_attribute(:raw_content, @query)
        @event_instance = @event.next_or_first_instance
        schedule = FactoryGirl.create :schedule
        @event_instance.update_attribute(:schedule_id, schedule.id)
      end

      subject { GetEventsByCategories.call(@event_category.slug, {}) }

      it "returns matching event instances" do
        expect(subject).to match_array [@event_instance]
      end

      context "when category is of type: Match Phrase" do
        before do
          @phrase = 'lightsaber sale'
          @event_category_with_phrase = FactoryGirl.create :event_category,
            name: 'Lightsaber Sales',
            query: "#{@phrase}, light saber sale",
            query_modifier: 'Match Phrase'
          @new_event = FactoryGirl.create :event, published: true
          @new_event.content.update_attribute(:raw_content, @phrase)
          @new_event_instance = @new_event.next_or_first_instance
          schedule = FactoryGirl.create :schedule
          @new_event_instance.update_attribute(:schedule_id, schedule.id)
        end

        subject { GetEventsByCategories.call(@event_category_with_phrase.slug, {}) }

        it "splits phrases and uses them to match" do
          expect(subject).to match_array [@new_event_instance]
        end
      end
    end
  end
end