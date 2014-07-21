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
#

require 'spec_helper'

describe ImportRecord do
  pending "add some examples to (or delete) #{__FILE__}"
end
