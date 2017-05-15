# == Schema Information
#
# Table name: event_categories
#
#  id             :integer          not null, primary key
#  name           :string
#  query          :string
#  query_modifier :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  slug           :string
#

class EventCategory < ActiveRecord::Base
  validates_presence_of :name, :query
  validates_uniqueness_of :name
  after_create :add_slug

  scope :alphabetical, ->{ order(name: :asc) }

  QUERY_MODIFIERS = ['AND', 'OR', 'Match Phrase']

  private

    def add_slug
      slug = name.parameterize.underscore
      update_attribute(:slug, slug)
    end

end
