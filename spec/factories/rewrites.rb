# == Schema Information
#
# Table name: rewrites
#
#  id          :integer          not null, primary key
#  source      :string(255)
#  destination :string(255)
#  created_by  :integer
#  updated_by  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
#
FactoryGirl.define do 
  factory :rewrite do
    source { Faker::Company.name }
    destination { Faker::Internet.url }
  end
end
