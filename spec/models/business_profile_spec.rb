# == Schema Information
#
# Table name: business_profiles
#
#  id                        :bigint(8)        not null, primary key
#  business_location_id      :bigint(8)
#  has_retail_location       :boolean          default(TRUE)
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  source                    :string(255)
#  source_id                 :string(255)
#  existence                 :float
#  feedback_count            :bigint(8)        default(0)
#  feedback_recommend_avg    :float            default(0.0)
#  feedback_price_avg        :float            default(0.0)
#  feedback_satisfaction_avg :float            default(0.0)
#  feedback_cleanliness_avg  :float            default(0.0)
#  archived                  :boolean          default(FALSE)
#
# Indexes
#
#  idx_16451_index_business_profiles_on_existence             (existence)
#  idx_16451_index_business_profiles_on_source_and_source_id  (source,source_id)
#

require 'spec_helper'

describe BusinessProfile, :type => :model do

  describe '#after_destroy' do
    before do
      @organization = FactoryGirl.create :organization
      @content = FactoryGirl.create :content, organization_id: @organization.id
      @business_profile = FactoryGirl.create :business_profile, content: @content
    end

    subject { @business_profile.destroy }

    context "when business profile is destroyed" do
      it "destroys associated organization" do
        expect{ subject }.to change{ Organization.count }.by(-1)
      end

      context 'when associated organization has other content' do
        before do
          @content2 = FactoryGirl.create :content, organization_id: @organization.id
        end

        it 'should not destroy associated organization' do
          expect{ subject }.to_not change{ Organization.count }
        end
      end

    end
  end

  describe '#claimed?' do
    before do
      @business_profile = FactoryGirl.create :business_profile
    end

    context "when business is not claimed" do
      it "returns false" do
        expect(@business_profile.claimed?).to be false
      end
    end

    context "when business is claimed" do
      before do
        @business_profile.content = FactoryGirl.create :content
        @business_profile.content.organization = FactoryGirl.create :organization
      end

      it "returns true" do
        expect(@business_profile.claimed?).to be true
      end
    end
  end

  describe 'convert_hours_to_standard' do
    context 'from factual format' do
      # a bunch of examples that cover the Factual import data:
      {
        "Mon-Fri 8:00 AM-6:00 PM" => ["Mo-Fr|08:00-18:00"],
        "Sun 12:00 PM-4:00 PM" => ["Su|12:00-16:00"],
        "Open Daily 12:00 AM-11:59 PM" => ["Mo-Su|00:00-23:59"],
        "Sat-Sun 8:00 AM-12:00 PM" => ["Sa-Su|08:00-12:00"],
        "Wed 6:00 AM-5:00 PM" => ["We|06:00-17:00"],
        "Tue-Sun 12:00 AM-2:00 AM, 10:00 AM-11:59 PM" => [
          "Tu-Su|00:00-02:00",
          "Tu-Su|10:00-23:59"
        ]
      }.each do |k,v|
        it { expect(BusinessProfile.convert_hours_to_standard(k, 'factual')).to eq(v) }
      end
    end
  end

end
