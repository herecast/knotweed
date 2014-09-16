# == Schema Information
#
# Table name: content_categories
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ContentCategory < ActiveRecord::Base
  attr_accessible :name

  has_many :content

  CATEGORIES = %w(beta_talk business campaign discussion event for_free lifestyle 
                  local_news nation_world offered presentation recommendation
                  sale_event sports wanted)

  def label
    name.titlecase
  end
end
