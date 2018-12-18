# frozen_string_literal: true

# == Schema Information
#
# Table name: rewrites
#
#  id            :integer          not null, primary key
#  source        :string(255)
#  destination   :string(255)
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  idx_16828_index_rewrites_on_created_by  (created_by)
#  idx_16828_index_rewrites_on_source      (source) UNIQUE
#  idx_16828_index_rewrites_on_updated_at  (updated_at)
#

FactoryGirl.define do
  factory :rewrite do
    sequence(:source) { |n| "green-acre-#{n}" }
    destination { Faker::Internet.url }
  end
end
