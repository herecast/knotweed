# == Schema Information
#
# Table name: wufoo_forms
#
#  id             :integer          not null, primary key
#  form_hash      :string(255)
#  email_field    :string(255)
#  name           :string(255)
#  call_to_action :text
#  controller     :string(255)
#  action         :string(255)
#  active         :boolean          default(TRUE)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

require 'spec_helper'

describe WufooForm do
  pending "add some examples to (or delete) #{__FILE__}"
end
