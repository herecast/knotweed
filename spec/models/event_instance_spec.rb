# == Schema Information
#
# Table name: event_instances
#
#  id                   :integer          not null, primary key
#  event_id             :integer
#  start_date           :datetime
#  end_date             :datetime
#  subtitle_override    :string(255)
#  description_override :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  presenter_name       :string(255)
#  schedule_id          :integer
#

require 'spec_helper'

describe EventInstance do
  before do
    @content = FactoryGirl.create :content, raw_content: 'cool description'
    @event = FactoryGirl.create :event, content: @content, subtitle: 'helpful subtitle'
  end

  describe "validation" do
    describe '#end_date_after_start_date' do
      context "when end date is before start date" do
        it 'returns validation error' do
          event_instance = FactoryGirl.build :event_instance, start_date: 2.days.from_now, end_date: 1.day.from_now
          expect(event_instance.valid?).to be false
        end
      end
    end
  end

  describe '#subtitle' do
    context "when no subtitle override" do
      it "returns subtitle" do
        expect(@event.event_instances.first.subtitle).to eq @event.subtitle
      end
    end

    context "when subtitle override present" do
      it "returns subtitle override" do
        @event.event_instances.first.update_attribute(:subtitle_override, "New Subtitle")
        expect(@event.event_instances.first.subtitle).to eq "New Subtitle"
      end
    end
  end

  describe '#description' do
    context "with no description override" do
      it "returns parent event description" do
        expect(@event.event_instances.first.description).to eq 'cool description'
      end
    end

    context "with description override" do
      it "overrides parent event description" do
        event_instance = @event.event_instances.first
        event_instance.update_attribute(:description_override, 'new description')
        expect(event_instance.description).to eq event_instance.description_override
      end
    end
  end
end
