# == Schema Information
#
# Table name: organizations
#
#  id                    :integer          not null, primary key
#  name                  :string(255)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  logo                  :string(255)
#  organization_id       :integer
#  website               :string(255)
#  notes                 :text
#  parent_id             :integer
#  category_override     :string(255)
#  org_type              :string(255)
#  display_attributes    :boolean          default(FALSE)
#  reverse_publish_email :string(255)
#  can_reverse_publish   :boolean          default(FALSE)
#

require 'spec_helper'

describe Organization do
  pending "add some examples to (or delete) #{__FILE__}"
end
