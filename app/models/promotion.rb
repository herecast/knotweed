# frozen_string_literal: true
# == Schema Information
#
# Table name: promotions
#
#  id              :bigint(8)        not null, primary key
#  banner          :string(255)
#  content_id      :bigint(8)
#  description     :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  promotable_id   :bigint(8)
#  promotable_type :string(255)
#  paid            :boolean          default(FALSE)
#  created_by_id   :bigint(8)
#  updated_by_id   :bigint(8)
#  share_platform  :string
#
# Indexes
#
#  idx_16765_index_promotions_on_content_id  (content_id)
#  idx_16765_index_promotions_on_created_by  (created_by_id)
#

class Promotion < ActiveRecord::Base
  include Auditable
  delegate :name, to: :organization, prefix: true
  belongs_to :content
  has_one :organization, through: :content

  belongs_to :promotable, polymorphic: true, inverse_of: :promotion
  delegate :banner_image, :redirect_url, :listserv, :sent_at, :banner_image?,
           :boost, to: :promotable, prefix: true

  # NOTE: this relationship is not identifying contents that it promotes,
  # but rather, contents that it is shown with on the consumer site.
  has_many :contents, through: :content_promotion_banner_impressions

  mount_uploader :banner, ImageUploader # same with this ^^
  # we are actually retaining the database column for now as well. At some point down the road,
  # we can remove these two lines of code and the database column

  accepts_nested_attributes_for :promotable
  accepts_nested_attributes_for :content

  validates_presence_of :description, if: :is_creative?

  PROMOTABLE_TYPES = ['PromotionBanner'].freeze

  UPLOAD_ENDPOINT = '/statements'

  scope :shares, -> { where('share_platform IS NOT NULL') }

  def promotable_attributes=(attributes)
    if PROMOTABLE_TYPES.include?(promotable_type)
      self.promotable ||= promotable_type.constantize.new
      self.promotable.assign_attributes(attributes)
    end
  end

  def is_creative?
    promotable_type == 'PromotionBanner'
  end
end
