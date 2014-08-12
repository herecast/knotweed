# == Schema Information
#
# Table name: organizations
#
#  id           :integer          not null, primary key
#  name         :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  org_type     :string(255)
#  notes        :text
#  tagline      :string(255)
#  links        :text
#  social_media :text
#  general      :text
#  header       :string(255)
#  logo         :string(255)
#

require 'spec_helper'

describe Organization do
  pending "add some examples to (or delete) #{__FILE__}"
end
