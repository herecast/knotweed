# frozen_string_literal: true

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


require 'rails_helper'

describe Role, type: :model do
  describe '#pretty_name' do
    let(:role) { FactoryGirl.create :role, name: name }
    let(:name) { 'important_admin_role' }
    subject { role.pretty_name }

    it 'should titlecase name' do
      expect(subject).to eq name.titlecase
    end
  end
end
