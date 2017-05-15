# == Schema Information
#
# Table name: event_categories
#
#  id             :integer          not null, primary key
#  name           :string
#  query          :string
#  query_modifier :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  slug           :string
#

require 'rails_helper'

RSpec.describe EventCategory, type: :model do

  describe "validation" do
    context "with no name" do
      it "is not valid" do
        event_category = FactoryGirl.build :event_category, name: nil
        expect(event_category).not_to be_valid
      end
    end

    context "with no query" do
      it "is not valid" do
        event_category = FactoryGirl.build :event_category, query: nil
        expect(event_category).not_to be_valid
      end
    end

    context "with non-unique name" do
      before do
        @name = 'Hotels on Hoth'
        @event_category = FactoryGirl.create :event_category, name: @name
      end

      it "is not valid" do
        event_category = FactoryGirl.build :event_category, name: @name
        expect(event_category).not_to be_valid
      end
    end

    context "with unique name and query" do
      it "is valid" do
        event_category = FactoryGirl.create :event_category,
          name: 'Droid repairshops on Alderaan',
          query: 'car repair alderaan'
        expect(event_category).to be_valid
      end
    end
  end
end
