# == Schema Information
#
# Table name: business_profiles
#
#  id                        :integer          not null, primary key
#  business_location_id      :integer
#  has_retail_location       :boolean          default(TRUE)
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  source                    :string(255)
#  source_id                 :integer
#  existence                 :integer
#  feedback_count            :integer          default(0)
#  feedback_recommend_avg    :float            default(0.0)
#  feedback_price_avg        :float            default(0.0)
#  feedback_satisfaction_avg :float            default(0.0)
#  feedback_cleanliness_avg  :float            default(0.0)
#

require 'spec_helper'

describe BusinessProfile do

  describe 'convert_hours_to_standard' do
    context 'from factual format' do
      # a bunch of examples that cover the Factual import data:
      { 
        "Mon-Fri 8:00 AM-6:00 PM" => "Mo-Fr|08:00-18:00",
        "Sun 12:00 PM-4:00 PM" => "Su|12:00-16:00",
        "Open Daily 12:00 AM-11:59 PM" => "Mo-Su|00:00-23:59",
        "Sat-Sun 8:00 AM-12:00 PM" => "Sa-Su|08:00-12:00",
        "Wed 6:00 AM-5:00 PM" => "We|06:00-17:00"
      }.each do |k,v|
        it { BusinessProfile.convert_hours_to_standard(k, 'factual').should eq(v) }
      end
    end
  end
  
end
