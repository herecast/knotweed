# == Schema Information
#
# Table name: listservs
#
#  id                    :integer          not null, primary key
#  name                  :string(255)
#  reverse_publish_email :string(255)
#  import_name           :string(255)
#  active                :boolean
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

require 'spec_helper'

describe Listserv, :type => :model do
  skip "add some examples to (or delete) #{__FILE__}"
end
