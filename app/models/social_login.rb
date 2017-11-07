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
# Indexes
#
#  index_social_logins_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_f53abcfb16  (user_id => users.id)
#

class SocialLogin < ActiveRecord::Base
  belongs_to :user
end
