# == Schema Information
#
# Table name: promotion_banners
#
#  id           :integer          not null, primary key
#  banner_image :string(255)
#  redirect_url :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require 'spec_helper'

describe PromotionBanner do
  pending "add some examples to (or delete) #{__FILE__}"
end
