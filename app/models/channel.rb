class Channel < ActiveRecord::Base
  serialize :categories, Array
  attr_accessible :categories, :name

  validates_uniqueness_of :name

  # gets corresponding channel for a piece of KIM content
  # (not currently mapped to our model Content)
  def self.get_channel_for_content(content)
    if content.features.has_key? "section"
      c = Channel.where("categories LIKE \"%#{content.features["section"].downcase}\\n%\"").first 
    else
      c = Channel.find_by_name("News") or Channel.first
    end
    return c.name.downcase
  end

end
