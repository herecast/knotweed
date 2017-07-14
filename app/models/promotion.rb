# == Schema Information
#
# Table name: promotions
#
#  id              :integer          not null, primary key
#  banner          :string(255)
#  organization_id :integer
#  content_id      :integer
#  description     :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  promotable_id   :integer
#  promotable_type :string(255)
#  paid            :boolean          default(FALSE)
#  created_by      :integer
#  updated_by      :integer
#  share_platform  :string
#

class Promotion < ActiveRecord::Base
  include Auditable
  belongs_to :organization
  delegate :name, to: :organization, prefix: true
  belongs_to :content

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
  PROMOTABLE_TYPES = ['PromotionBanner']

  UPLOAD_ENDPOINT = "/statements"

  scope :shares, ->{ where('share_platform IS NOT NULL') }

  def promotable_attributes=(attributes)
    if PROMOTABLE_TYPES.include?(promotable_type)
      self.promotable ||= self.promotable_type.constantize.new
      self.promotable.assign_attributes(attributes)
    end
  end

end
