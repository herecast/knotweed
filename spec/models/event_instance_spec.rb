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
  	@event = FactoryGirl.create :event, subtitle: 'helpful subtitle'
  end

  describe "validation" do
  	describe '#end_date_after_start_date' do
  		context "when end date is after start date" do
  			it 'returns validation error' do
  				event_instance = FactoryGirl.build :event_instance, start_date: 2.days.from_now, end_date: 1.day.from_now
  				event_instance.save
  				expect(event_instance.errors.count).to eq 1
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
  end

  describe '#description' do
  	context "with description override" do
  		it "overrides parent event description" do
  			event_instance = @event.event_instances.first
  			event_instance.update_attribute(:description_override, 'new description')
  			expect(event_instance.description).to eq event_instance.description_override
  		end
  	end
  end
end
