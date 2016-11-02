require 'spec_helper'

describe Feature, type: :model do
  it { is_expected.to have_db_column(:name).of_type(:string) }
  it { is_expected.to have_db_column(:description).of_type(:text) }
  it { is_expected.to have_db_column(:active).of_type(:boolean) }

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
end
