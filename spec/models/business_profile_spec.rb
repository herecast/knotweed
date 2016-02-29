require 'spec_helper'

describe BusinessProfile do
  before do
    @business_profile = FactoryGirl.create :business_profile
  end

  describe 'feedback' do
    before do
      @bf1 = FactoryGirl.create :business_feedback, business_profile: @business_profile,
        satisfaction: true, cleanliness: true, price: false, recommend: false
      @bf2 = FactoryGirl.create :business_feedback, business_profile: @business_profile,
        satisfaction: true, cleanliness: false, price: true, recommend: false
    end

    it 'should return the correct averages feedback values' do
      @business_profile.feedback.should eq({
        satisfaction: 1,
        cleanliness: 0.5,
        price: 0.5,
        recommend: 0
      })
    end
  end
end
