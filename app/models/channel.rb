class Channel < ActiveRecord::Base
  serialize :categories, Array
  attr_accessible :categories, :name

  validates_uniqueness_of :name

  # gets corresponding channel for a piece of KIM content
  # (not currently mapped to our model Content)
  def self.get_channels_for_content(content)
    channels = []
    
    if content.features.has_key? "CATEGORIES"
      cats = content.features["CATEGORIES"].split(',').map { |c| c.strip }
      cats.each do |category|
        chan = Channel.where("categories LIKE \"%#{category}\\n%\"").first
        unless chan.nil?
          channels << chan
        end
      end
    end
    if channels.empty?
      channels << Channel.find_by_name("News") unless Channel.find_by_name("News").nil?
    end
    
    return channels
  end

end
