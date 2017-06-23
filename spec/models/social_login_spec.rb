require 'rails_helper'

RSpec.describe SocialLogin, type: :model do
  it { is_expected.to have_db_column(:user_id).of_type(:integer) }
  it { is_expected.to have_db_column(:provider).of_type(:string) }
  it { is_expected.to have_db_column(:uid).of_type(:string) }
  it { is_expected.to have_db_column(:extra_info).of_type(:json) }
end
