require 'rails_helper'

RSpec.describe ContentLocation, type: :model do
  it { is_expected.to belong_to :content }
  it { is_expected.to belong_to :location }
  it { is_expected.to have_db_column(:location_type).of_type(:string) }
end
