# == Schema Information
#
# Table name: messages
#
#  id            :integer          not null, primary key
#  created_by_id :integer
#  controller    :string(255)
#  action        :string(255)
#  start_date    :datetime
#  end_date      :datetime
#  content       :text
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

require 'spec_helper'

describe Message, :type => :model do

  describe "active scope" do
    before do
      @active_message = FactoryGirl.create :message
      @expired_message = FactoryGirl.create :message, :inactive
      @not_yet_active_message = FactoryGirl.create :message, start_date: 1.week.from_now
    end

    it "should return only active messages" do
      expect(Message.active.include?(@active_message)).to eq(true)
      expect(Message.active.include?(@expired_message)).to eq(false)
      expect(Message.active.include?(@not_yet_active_message)).to eq(false)
    end
  end

  describe "validation" do
    describe "end_date_greater_than_start_date" do
      it "should be invalid" do
        m = FactoryGirl.build(:message)
        m.end_date = m.start_date - 1.day
        expect(m).not_to be_valid
      end
    end
  end

  describe "#active?" do
    context "when active" do
      it "returns true" do
        message = FactoryGirl.create :message, start_date: DateTime.current - 1, end_date: nil
        expect(message.active?).to be true
      end
    end

    context "when innactive" do
      it "returns false" do
        message = FactoryGirl.create :message, :inactive
        expect(message.active?).to be false
      end
    end
  end

end
