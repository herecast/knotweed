# == Schema Information
#
# Table name: notifiers
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  notifyable_id   :integer
#  notifyable_type :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

require 'spec_helper'

describe Notifier, :type => :model do
  skip "add some examples to (or delete) #{__FILE__}"
end
