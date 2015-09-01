# == Schema Information
#
# Table name: promotions
#
#  id              :integer          not null, primary key
#  active          :boolean
#  banner          :string(255)
#  publication_id  :integer
#  content_id      :integer
#  description     :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  promotable_id   :integer
#  promotable_type :string(255)
#  paid            :boolean          default(FALSE)
#

class Promotion < ActiveRecord::Base
  belongs_to :publication
  belongs_to :content

  belongs_to :promotable, polymorphic: true, inverse_of: :promotion

  # NOTE: this relationship is not identifying contents that it promotes,
  # but rather, contents that it is shown with on the consumer site.
  has_many :contents, through: :content_promotion_banner_impressions

  # TODO: At some point we probably want to lock this down a bit more so it's not so easy to attach 
  # promotions to any content/publication
  attr_accessible :active, :description, :content, :publication,
                  :publication_id, :content_id, :target_url,
                  :promotable_attributes, :promotable_type, :paid,
                  :banner # note this attribute no longer exists, but needs to be
                  # in our code until afer the migration is run
  mount_uploader :banner, ImageUploader # same with this ^^
  # we are actually retaining the database column for now as well. At some point down the road,
  # we can remove these two lines of code and the database column

  accepts_nested_attributes_for :promotable
  after_initialize :init
  # after_save :update_active_promotions

  UPLOAD_ENDPOINT = "/statements"

  def init
    self.active = true if self.active.nil?
  end

  # def update_active_promotions
  #   if promotable_type == "PromotionBanner"
  #     PromotionBanner::update_active_promotions
  #   end
  # end

  protected

  def build_promotable(params, assignment_options)
    self.promotable = promotable_type.constantize.new(params)
  end
end
