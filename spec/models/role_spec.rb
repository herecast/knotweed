# frozen_string_literal: true

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
