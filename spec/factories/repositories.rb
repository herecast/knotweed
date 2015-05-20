# == Schema Information
#
# Table name: repositories
#
#  id                      :integer          not null, primary key
#  name                    :string(255)
#  dsp_endpoint            :string(255)
#  sesame_endpoint         :string(255)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  graphdb_endpoint        :string(255)
#  annotate_endpoint       :string(255)
#  solr_endpoint           :string(255)
#  recommendation_endpoint :string(255)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :repository do
    name "Test Repo"
    dsp_endpoint "http://23.92.16.168:8080"
    sesame_endpoint "http://23.92.16.168:8081/openrdf-sesame/repositories/subtext"
    recommendation_endpoint "http://23.92.16.168:8081/openrdf-sesame/repositories/subtext"
  end
end
