# == Schema Information
#
# Table name: roles
#
#  id            :bigint(8)        not null, primary key
#  name          :string(255)
#  resource_id   :bigint(8)
#  resource_type :string(255)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  idx_16837_index_roles_on_name                                    (name)
#  idx_16837_index_roles_on_name_and_resource_type_and_resource_id  (name,resource_type,resource_id)
#

FactoryGirl.define do
  factory :role do
    name 'admin'
  end
end
