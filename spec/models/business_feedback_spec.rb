require 'spec_helper'

describe BusinessFeedback, :type => :model do

  context 'after saving' do
    let(:business_profile) { FactoryGirl.create :business_profile }
    subject { FactoryGirl.build :business_feedback, business_profile: business_profile }

    [:feedback_count, :feedback_price_avg, :feedback_recommend_avg, :feedback_satisfaction_avg, :feedback_cleanliness_avg].each do |field|

      it "updates #business_profile.#{field.to_s}" do
        expect {
          subject.save!
          subject.run_callbacks(:commit)
        }.to change {
          subject.business_profile.reload.send field
        }
      end
    end
  end

  context 'after deleting' do
    let(:business_profile) { FactoryGirl.create :business_profile }
    subject { FactoryGirl.create :business_feedback, business_profile: business_profile }

    [:feedback_count, :feedback_price_avg, :feedback_recommend_avg, :feedback_satisfaction_avg, :feedback_cleanliness_avg].each do |field|

      it "updates #business_profile.#{field.to_s}" do
        expect {
          subject.destroy
          subject.run_callbacks(:commit)
        }.to change {
          subject.business_profile.reload.send field
        }
      end
    end
  end
end
