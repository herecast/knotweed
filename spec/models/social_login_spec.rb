# == Schema Information
#
# Table name: social_logins
#
#  id         :integer          not null, primary key
#  user_id    :integer          not null
#  provider   :string           not null
#  uid        :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  extra_info :json
#

require 'rails_helper'

RSpec.describe SocialLogin, type: :model do
  it { is_expected.to have_db_column(:user_id).of_type(:integer) }
  it { is_expected.to have_db_column(:provider).of_type(:string) }
  it { is_expected.to have_db_column(:uid).of_type(:string) }
  it { is_expected.to have_db_column(:extra_info).of_type(:json) }
end
