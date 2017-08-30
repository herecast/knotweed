# == Schema Information
#
# Table name: images
#
#  id             :integer          not null, primary key
#  caption        :string(255)
#  credit         :string(255)
#  image          :string(255)
#  imageable_type :string(255)
#  imageable_id   :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  source_url     :string(400)
#  primary        :boolean          default(FALSE)
#  width          :integer
#  height         :integer
#  file_extension :string
#  position       :integer          default(0)
#

FactoryGirl.define do
  factory :image do
    primary false
    image File.open(File.join(Rails.root, '/spec/fixtures/photo.jpg'))

    trait :primary do
      primary true
    end
  end
end
