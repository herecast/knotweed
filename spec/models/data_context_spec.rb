# == Schema Information
#
# Table name: data_contexts
#
#  id         :integer          not null, primary key
#  context    :string(255)
#  loaded     :boolean          default(FALSE)
#  last_load  :datetime
#  archived   :boolean          default(FALSE)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'spec_helper'

describe DataContext do
  pending "add some examples to (or delete) #{__FILE__}"
end
