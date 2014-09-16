# == Schema Information
#
# Table name: consumer_apps
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  uri           :string(255)
#  repository_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

require 'spec_helper'

describe ConsumerApp do
  pending "add some examples to (or delete) #{__FILE__}"
end
