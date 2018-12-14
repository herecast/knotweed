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

class Role < ActiveRecord::Base
  has_and_belongs_to_many :users, :join_table => :users_roles
  belongs_to :resource, :polymorphic => true

  scopify

  scope :non_resource_roles, -> { where(resource_id: nil) }

  def pretty_name
    name.gsub('_', ' ').capitalize
  end

  # just a shortcut so we don't have to write
  #     Role.find_or_create_by(name: 'hello')
  # every time
  def self.get(name)
    self.find_or_create_by(name: name)
  end
end
