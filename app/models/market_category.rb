#== Schema Information
#
# Table name: market_categories
# 
# id                  :integer
# name                :string
# query               :string
# category_image      :string
# detail_page_banner  :string
# featured            :boolean    default(FALSE)
# trending            :boolean    default(FALSE)
# created_at          :datetime
# updated_at          :datetime
class MarketCategory < ActiveRecord::Base
  validates_presence_of :name
  validate :not_featured_and_trending
  validate :trending_limit, if: :trending_changed_to_true?
  validate :featured_limit, if: :featured_changed_to_true?

  mount_uploader :category_image, ImageUploader
  mount_uploader :detail_page_banner, ImageUploader
  
  scope :trending, -> { where(trending: true) }
  scope :featured, -> { where(featured: true) }

  def self.default_search_options
    opts = {}
    opts[:order] = { pubdate: :desc }
    opts[:where] = {
      pubdate: 30.days.ago..Time.zone.now,
      root_content_category_id: ContentCategory.find_by_name('market').id,
      published: 1,
    }
    opts[:include] = [:channel]
    opts
  end

  def self.query_modifier_options
    ['AND', 'OR', 'Match Phrase']
  end

  def formatted_modifier_options
    case query_modifier
    when "OR"
      { operator: "or" }
    when "Match Phrase"
      { match: :phrase }
    else
      {}
    end
  end

  def formatted_query
    if query_modifier == "Match Phrase"
      query
    else
      query.split(/[,\s]+/).join(" ")
    end
  end

  private

  def not_featured_and_trending
    if (self.trending && self.featured)
      self.errors[:base] << "Cannot Be Featured AND Trending"
    end
  end

  def trending_limit
      trending_count = MarketCategory.where(trending: true).count
      if trending_count >= 3
        self.errors[:trending] << "can only be true for 3 categories"
      end
  end

  def featured_limit
    featured_count = MarketCategory.where(featured: true).count
    if featured_count >= 6
      self.errors[:featured] << "can only be true for 6 categories"
    end
  end
  
  def featured_changed_to_true?
    featured_changed? && featured_change[1]
  end
  
  def trending_changed_to_true?
    trending_changed? && trending_change[1]
  end
end
