# frozen_string_literal: true

# == Schema Information
#
# Table name: images
#
#  id             :bigint(8)        not null, primary key
#  caption        :string(255)
#  credit         :string(255)
#  image          :string(255)
#  imageable_type :string(255)
#  imageable_id   :bigint(8)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  source_url     :string(400)
#  primary        :boolean          default(FALSE)
#  width          :integer
#  height         :integer
#  file_extension :string
#  position       :integer          default(0)
#
# Indexes
#
#  idx_16634_index_images_on_imageable_type_and_imageable_id  (imageable_type,imageable_id)
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
