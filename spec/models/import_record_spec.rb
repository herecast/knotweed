# == Schema Information
#
# Table name: import_records
#
#  id             :integer          not null, primary key
#  import_job_id  :integer
#  items_imported :integer          default(0)
#  failures       :integer          default(0)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  filtered       :integer          default(0)
#

require 'spec_helper'

describe ImportRecord, :type => :model do
  skip "add some examples to (or delete) #{__FILE__}"
end
