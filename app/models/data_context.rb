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

class DataContext < ActiveRecord::Base

  has_many :datasets

  default_scope { where archived: false }
end
