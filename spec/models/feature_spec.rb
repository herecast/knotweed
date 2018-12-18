# frozen_string_literal: true

# == Schema Information
#
# Table name: features
#
#  id          :integer          not null, primary key
#  name        :string
#  description :text
#  active      :boolean
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  options     :text
#

require 'spec_helper'

describe Feature, type: :model do
  it { is_expected.to have_db_column(:name).of_type(:string) }
  it { is_expected.to have_db_column(:description).of_type(:text) }
  it { is_expected.to have_db_column(:active).of_type(:boolean) }
  it { is_expected.to have_db_column(:options).of_type(:text) }

  describe 'validations' do
    before do
      @feature = FactoryGirl.build(:feature, name: nil)
    end
    it 'requires name to be present' do
      @feature.valid?
      expect(@feature.errors).not_to be_nil
      expect(@feature.errors.full_messages).to include "Name can't be blank"
    end
  end

  describe 'validate_json' do
    context 'with valid json options' do
      before do
        subject.options = '{"foo": "bar"}'
        subject.name = 'My Feature'
      end

      it 'is valid' do
        expect(subject.valid?).to eq true
      end
    end

    context 'with invalid json options' do
      before do
        subject.name = 'My Feature'
        subject.options = '{"invalid": "json}'
      end

      it 'adds the correct error message' do
        subject.valid?
        expect(subject.errors.count).to eq 1
        expect(subject.errors.messages[:options].first).to eq 'Invalid JSON'
      end
    end
  end
end
