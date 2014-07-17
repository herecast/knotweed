# == Schema Information
#
# Table name: promotions
#
#  id             :integer          not null, primary key
#  active         :boolean
#  banner         :string(255)
#  publication_id :integer
#  content_id     :integer
#  description    :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

require 'spec_helper'

describe Promotion do
  pending "add some examples to (or delete) #{__FILE__}"
end
