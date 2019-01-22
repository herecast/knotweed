# frozen_string_literal: true
# == Schema Information
#
# Table name: business_feedbacks
#
#  id                  :bigint(8)        not null, primary key
#  created_by_id       :bigint(8)
#  updated_by_id       :bigint(8)
#  business_profile_id :bigint(8)
#  satisfaction        :boolean
#  cleanliness         :boolean
#  price               :boolean
#  recommend           :boolean
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

require 'spec_helper'

describe BusinessFeedback, type: :model do
  context 'after saving' do
    let(:business_profile) { FactoryGirl.create :business_profile }
    subject { FactoryGirl.build :business_feedback, business_profile: business_profile }

    %i[feedback_count feedback_price_avg feedback_recommend_avg feedback_satisfaction_avg feedback_cleanliness_avg].each do |field|
      it "updates #business_profile.#{field}" do
        expect do
          subject.save!
          subject.run_callbacks(:commit)
        end.to change {
          subject.business_profile.reload.send field
        }
      end
    end
  end

  context 'after deleting' do
    let(:business_profile) { FactoryGirl.create :business_profile }
    subject { FactoryGirl.create :business_feedback, business_profile: business_profile }

    %i[feedback_count feedback_price_avg feedback_recommend_avg feedback_satisfaction_avg feedback_cleanliness_avg].each do |field|
      it "updates #business_profile.#{field}" do
        expect do
          subject.destroy
          subject.run_callbacks(:commit)
        end.to change {
          subject.business_profile.reload.send field
        }
      end
    end
  end
end
