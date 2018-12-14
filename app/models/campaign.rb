# frozen_string_literal: true

# == Schema Information
#
# Table name: campaigns
#
#  id            :integer          not null, primary key
#  listserv_id   :integer
#  community_ids :integer          default([]), is an Array
#  sponsored_by  :string
#  digest_query  :text
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  title         :string
#  preheader     :string
#  promotion_ids :integer          default([]), is an Array
#
# Indexes
#
#  index_campaigns_on_community_ids  (community_ids)
#  index_campaigns_on_listserv_id    (listserv_id)
#
# Foreign Keys
#
#  fk_rails_ac529cad68  (listserv_id => listservs.id)
#

class Campaign < ActiveRecord::Base
  include HasPromotionForBanner

  belongs_to :listserv

  validate :require_a_community
  validate :prevent_community_overlap
  validate :no_altering_queries

  def communities=(list)
    write_attribute :community_ids, (list || []).collect(&:id).sort
  end

  def communities
    if community_ids.any?
      Location.where(id: community_ids)
    else
      []
    end
  end

  def promotions_list=(list)
    write_attribute(:promotion_ids, list.split(/[,\s]+/))
  end

  def promotions_list
    promotion_ids.join(', ')
  end

  def contents_from_custom_query
    custom_ids = custom_digest_results.map { |result| result['id'].to_i }
    Content.where(id: custom_ids).sort_by { |c| custom_ids.index(c.id) }
  end

  def no_altering_queries
    if digest_query?
      query_array = digest_query.upcase.split(' ')
      reserved_commands = %w[INSERT UPDATE DELETE DROP TRUNCATE]
      has_reserved_words = query_array.any? { |word| reserved_commands.include?(word) }
      errors.add(:digest_query, 'Commands to alter data are not allowed') if has_reserved_words
    end
  end

  protected

  def require_a_community
    unless communities.any?
      errors.add(:community_ids, 'must have at least one community')
    end
  end

  def prevent_community_overlap
    community_overlap = siblings.any? do |sib|
      (sib.community_ids & community_ids).any?
    end

    if community_overlap
      errors.add :community_ids, 'cannot have community included in another campaign'
    end
  end

  def siblings
    self.class.where(listserv_id: listserv_id).where.not(id: id)
  end

  def promotions
    if promotion_ids.any?
      Promotion.where(id: promotion_ids).sort_by { |p| promotion_ids.index(p.id) }
    else
      []
    end
  end

  private

  def get_query
    ActiveRecord::Base.connection.execute(digest_query)
  end

  def custom_digest_results
    get_query.to_a
  end
end
