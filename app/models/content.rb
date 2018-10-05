# encoding: utf-8
# == Schema Information
#
# Table name: contents
#
#  id                        :integer          not null, primary key
#  title                     :string(255)
#  subtitle                  :string(255)
#  authors                   :string(255)
#  raw_content               :text
#  issue_id                  :integer
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  guid                      :string(255)
#  pubdate                   :datetime
#  source_category           :string(255)
#  url                       :string(255)
#  origin                    :string(255)
#  page                      :string(255)
#  authoremail               :string(255)
#  organization_id           :integer
#  quarantine                :boolean          default(FALSE)
#  timestamp                 :datetime
#  parent_id                 :integer
#  content_category_id       :integer
#  category_reviewed         :boolean          default(FALSE)
#  has_event_calendar        :boolean          default(FALSE)
#  channelized_content_id    :integer
#  published                 :boolean          default(FALSE)
#  channel_type              :string(255)
#  channel_id                :integer
#  root_content_category_id  :integer
#  view_count                :integer          default(0)
#  comment_count             :integer          default(0)
#  commenter_count           :integer          default(0)
#  created_by_id             :integer
#  updated_by_id             :integer
#  banner_click_count        :integer          default(0)
#  similar_content_overrides :text
#  banner_ad_override        :integer
#  root_parent_id            :integer
#  deleted_at                :datetime
#  authors_is_created_by     :boolean          default(FALSE)
#  subscriber_mc_identifier  :string
#  biz_feed_public           :boolean
#  sunset_date               :datetime
#  promote_radius            :integer
#  ad_promotion_type         :string
#  ad_campaign_start         :date
#  ad_campaign_end           :date
#  ad_max_impressions        :integer
#  short_link                :string
#  ad_invoiced_amount        :float
#  first_served_at           :datetime
#  removed                   :boolean          default(FALSE)
#  ad_invoice_paid           :boolean          default(FALSE)
#  ad_commission_amount      :float
#  ad_commission_paid        :boolean          default(FALSE)
#  ad_services_amount        :float
#  ad_services_paid          :boolean          default(FALSE)
#  ad_sales_agent            :integer
#  ad_promoter               :integer
#  latest_activity           :datetime
#  has_future_event_instance :boolean
#  alternate_title           :string
#  alternate_organization_id :integer
#  alternate_authors         :string
#  alternate_text            :string
#  alternate_image_url       :string
#  location_id               :integer
#
# Indexes
#
#  idx_16527_authors                                     (authors)
#  idx_16527_categories                                  (source_category)
#  idx_16527_content_category_id                         (content_category_id)
#  idx_16527_guid                                        (guid)
#  idx_16527_index_contents_on_authoremail               (authoremail)
#  idx_16527_index_contents_on_channel_id                (channel_id)
#  idx_16527_index_contents_on_channel_type              (channel_type)
#  idx_16527_index_contents_on_channelized_content_id    (channelized_content_id)
#  idx_16527_index_contents_on_created_by                (created_by_id)
#  idx_16527_index_contents_on_parent_id                 (parent_id)
#  idx_16527_index_contents_on_published                 (published)
#  idx_16527_index_contents_on_root_content_category_id  (root_content_category_id)
#  idx_16527_index_contents_on_root_parent_id            (root_parent_id)
#  idx_16527_pubdate                                     (pubdate)
#  idx_16527_source_id                                   (organization_id)
#  idx_16527_title                                       (title)
#  index_contents_on_location_id                         (location_id)
#
# Foreign Keys
#
#  fk_rails_4a833c7bbc  (location_id => locations.id)
#

require 'fileutils'
require 'builder'
include ActionView::Helpers::TextHelper
class Content < ActiveRecord::Base
  extend Enumerize
  include Auditable
  include Incrementable

  before_create :set_latest_activity
  def set_latest_activity
    self.latest_activity = pubdate.present? ? pubdate : Time.current
  end

  before_save :conditionally_update_latest_activity
  def conditionally_update_latest_activity
    if channel_type == 'MarketPost' && channel.sold_changed? && pubdate >= 30.days.ago
      self.latest_activity = Time.current
    elsif content_type == :news && pubdate_changed?
      self.latest_activity = pubdate
    end
  end

  searchkick callbacks: :async,
    batch_size: 750,
    index_prefix: Figaro.env.searchkick_index_prefix,
    searchable: [:content, :title, :subtitle, :author_name, :organization_name],
    settings: {
      analysis: {
        analyzer: {
          #@TODO! This changes in newer searchkick versions.
          #see: https://github.com/ankane/searchkick/blob/master/lib/searchkick/index_options.rb
          searchkick_index: {
            :char_filter=>["html_strip", "ampersand"]
          }
        }
      }
    }

  scope :search_import, -> {
    includes(:root_content_category,
             :content_category,
             :promotions,
             :images,
             :created_by,
             children: [:created_by],
             parent: [:root_content_category],
             content_locations: [:location],
             content_category: [:parent],
             organization: [:locations, :consumer_active_base_locations, :organization_locations])
      .where('organization_id NOT IN (4,5,328)')
      .where('root_content_category_id > 0')
      .where('raw_content IS NOT NULL')
      .where("raw_content != ''")
  }

  def search_serializer
    SearchIndexing::ContentSerializer
  end

  def search_data
    search_serializer.new(self).serializable_hash
  end

  def is_listserv?
    organization_id == Organization::LISTSERV_ORG_ID
  end

  def should_index?
    deleted_at.blank? && raw_content.present?
  end

  def self.default_search_opts
    {
      order: { pubdate: :desc },
      where: {
        pubdate: 5.years.ago..Time.zone.now
      }
    }
  end

  def all_loc_slugs
    # this is to work around a bug https://github.com/rails/rails/pull/25976 which is fixed
    # in rails 5.0.1. pluck() prevents previously loaded includes from being used
    if association(:locations).loaded?
      locs = locations.map(&:slug)
    elsif association(:content_locations).loaded?
      locs = content_locations.map{|cl| cl.location.slug}
    else
      locs = locations.pluck(:slug)
    end
    if content_type != :talk && organization.present? && organization.name != 'Listserv'
      # same work-around here - remove when rails is upgraded
      if organization.association(:locations).loaded?
        locs += organization.locations.map(&:slug)
      elsif organization.association(:organization_locations).loaded?
        locs = organization.organization_locations.map do |ol|
          ol.location.slug
        end
      else
        locs += organization.locations.pluck(:slug)
      end
    end
    locs.uniq
  end

  after_commit :reindex_associations_async
  def reindex_associations_async
    if channel.present? and channel.is_a? Event
      channel.event_instances.each do |ei|
        ei.reindex_async
      end
    end
  end

  belongs_to :issue
  belongs_to :location

  has_many :category_corrections

  has_many :content_reports
  has_many :payments

  # NOTE: this relationship is tracking display of promotion banners with
  # contents, not the promotion of contents (which is handled through the promotion model).
  has_many :content_promotion_banner_loads
  has_many :promotion_banners, through: :content_promotion_banner_loads
  has_many :content_locations, dependent: :destroy
  accepts_nested_attributes_for :content_locations, allow_destroy: true
  has_many :locations, through: :content_locations
  has_many :base_locations, -> { where('"content_locations"."location_type" = \'base\'') },
           through: :content_locations, source: :location
  has_many :about_locations, -> { where('"content_locations"."location_type" = \'about\'') },
           through: :content_locations, source: :location

  has_many :profile_metrics, dependent: :destroy

  validate :if_ad_promotion_type_sponsored_must_have_ad_max_impressions
  validates :ad_invoiced_amount, numericality: { greater_than: 0 }, if: 'ad_invoiced_amount.present?'
  validates :ad_commission_amount, numericality: { greater_than: 0 }, if: 'ad_commission_amount.present?'
  validates :ad_services_amount, numericality: { greater_than: 0 }, if: 'ad_services_amount.present?'

  def base_locations=locs
    locs.each do |l|
      ContentLocation.find_or_initialize_by(
        content: self,
        location: l
      ).base!
    end
  end

  def about_locations=locs
    locs.each do |l|
      ContentLocation.find_or_initialize_by(
        content: self,
        location: l
      ).about!
    end
  end

  has_many :organization_content_tags, dependent: :destroy
  has_many :organizations, through: :organization_content_tags

  has_many :images, -> { order("images.primary DESC") }, as: :imageable, inverse_of: :imageable, dependent: :destroy
  accepts_nested_attributes_for :images, allow_destroy: true

  belongs_to :organization
  accepts_nested_attributes_for :organization
  delegate :name, to: :organization, prefix: true, allow_nil: true

  belongs_to :parent, class_name: "Content"
  belongs_to :root_parent, class_name: self.name
  delegate :view_count, :comment_count, :commenter_count, to: :parent, prefix: true
  has_many :children, class_name: "Content", foreign_key: "parent_id"
  has_many :comments, -> {
    where('channel_type = ?', 'Comment')
  }, class_name: "Content", foreign_key: "parent_id"

  has_many :promotions
  has_many :user_bookmarks

  belongs_to :content_category
  belongs_to :root_content_category, class_name: 'ContentCategory'

  # mapping to content record that represents the channelized content
  belongs_to :channelized_content, class_name: "Content"
  has_one :unchannelized_original, class_name: "Content", foreign_key: "channelized_content_id"
  has_one :sales_agent, class_name: 'User', primary_key: "ad_sales_agent", foreign_key: "id"
  has_one :promoter, class_name: 'User', primary_key: "ad_promoter", foreign_key: "id"

  attr_accessor :tier # this is not stored on the database, but is used to generate a tiered tree
  # for the API

  validates_presence_of :raw_content, :title, if: :is_event?
  validates_presence_of :raw_content, :title, if: :is_market_post?
  validates_presence_of :organization_id, :title, :ad_promotion_type, :ad_campaign_start, :ad_campaign_end, if: :is_campaign?

  # check if it should be marked quarantined
  before_save :mark_quarantined
  before_save :set_guid

  # this has to be after save to accomodate the situation
  # where we are creating new content with no parent
  after_save :set_root_parent_id

  after_create :hide_campaign_from_public_view

  # channel relationships
  belongs_to :channel, polymorphic: true, inverse_of: :content

  # THESE ARE JUST SEMI-FAKE ASSOCIATIONS FOR RANSACK TO USE FOR CONTENTS#INDEX
  # DO NOT USE OTHERWISE
  belongs_to :event, foreign_key: 'channel_id'
  accepts_nested_attributes_for :event, allow_destroy: true
  has_many :event_instances, through: :event
  belongs_to :market_post, foreign_key: 'channel_id'
  accepts_nested_attributes_for :market_post, allow_destroy: true

  scope :events, -> { joins(:content_category).where("content_categories.name = ? or content_categories.name = ?",
                                                     "event", "sale_event") }
  scope :market_posts, -> { where(channel_type: 'MarketPost') }

  scope :published, -> { where(published: true) }

  scope :if_event_only_when_instances, -> {
    where("(CASE #{table_name}.channel_type WHEN 'Event' THEN
              (select count(*)
               from event_instances ei
               join events e on ei.event_id = e.id
               where e.id = #{table_name}.channel_id)
              ELSE
                1
              END) > 0")
  }

  scope :not_deleted, -> { where(deleted_at: nil) }
  scope :not_removed, -> { where(removed: false) }
  scope :not_listserv, -> { where("organization_id <> ?", Organization::LISTSERV_ORG_ID) }
  scope :is_dailyuv, -> { where(organization_id: ConsumerApp.find_by_name('Daily UV').organizations) }
  scope :not_comment, -> { where(parent_id: nil) }
  scope :only_categories, ->(names) {
    joins("JOIN content_categories AS category ON root_content_category_id = category.id")\
    .where("category.name IN (?)", names)
  }
  # not checking for org base locations is intentional
  scope :not_all_base_locations, -> {
    where("EXISTS(select 1 from content_locations where content_id = contents.id AND (location_type != 'base' OR location_type IS NULL)) OR NOT EXISTS(select 1 from content_locations where content_id = contents.id)")
  }

  scope :ad_campaign_active, ->(date=Date.current) { where("ad_campaign_start <= ?", date)
    .where("ad_campaign_end >= ?", date) }

  UGC_ORIGIN = 'UGC'

  CATEGORIES = %w(beta_talk business campaign discussion event for_free lifestyle
                  local_news nation_world offered presentation recommendation
                  sale_event sports wanted)

  BLACKLIST_BLOCKS = File.readlines(Rails.root.join('lib', 'content_blacklist.txt'))

  # ensure that we never save titles with leading/trailing whitespace
  def title=t
    write_attribute(:title, t.to_s.strip)
  end

  def primary_image
    images.find(&:primary) or images.sort_by(&:id).first
  end

  def primary_image=(image)
    # make sure all other images are secondary
    images.where(primary: true).each do |i|
      i.update_attribute(:primary, false) unless i == image
    end
    image.update_attribute(:primary, true)
  end

  # holdover from when we used to use processed_content by preference.
  # Seemed easier to keep this method, but just make it point directly to raw content
  # than to remove references to the method altogether
  def content
    raw_content
  end

  def category
    return content_category.name unless content_category.nil?
  end

  def category= new_cat
    cat = ContentCategory.find_or_create_by(name: new_cat) unless new_cat.nil?
    self.content_category = cat
  end

  def content_type
    prefix = root_content_category.try(:name)
    # convert talk_of_the_town to talk
    prefix = 'talk' if prefix == 'talk_of_the_town'
    if parent_id.present?
      if channel_type == "Comment" && parent_id != id
        prefix = 'comment'
      end
    end
    prefix.to_s.to_sym
  end

  def content_type=t
    cat_name = t.to_s
    cat_name = 'talk' if t.to_s == 'talk_of_the_town'
    if cat_name != content_type.to_s
      self.category = cat_name
    end
  end

  # check that doc validates our xml requirements
  # if not, mark it as quarantined
  def mark_quarantined
    if title.present? and organization.present? and pubdate.present? and strip_tags(sanitized_content).present?
      self.quarantine = false
    else
      self.quarantine = true
    end
    true
  end

  # if guid is empty, set with our own
  def set_guid
    unless self.guid.present?
      self.guid = ""
      if title.present?
        self.guid << title.gsub(" ", "_").gsub("/", "-")
      else
        self.guid << "#{rand(10000)}-#{rand(10000)}"
      end
      self.guid << "-" << pubdate.strftime("%Y-%m-%d") if pubdate.present?
      self.guid = CGI::escape guid
    end
  end

  def set_root_content_category_id
    if content_category.present?
      self.root_content_category = content_category.parent || content_category
    else
      self.root_content_category = nil
    end
  end

  def content_category_id=id
    super(id)
    set_root_content_category_id
    id
  end

  def content_category=cat
    super(cat)
    set_root_content_category_id
    cat
  end

  def set_root_parent_id
    # we don't want to be calling find_root_parent every time because it's costly,
    # so we rely on whether or not the parent_id changed as that's the only way -- within
    # a single transaction -- that root_parent_id could've changed
    if parent_id_changed? or parent_id.nil? # the latter part of this conditional covers creating
      # new content that doesn't have a parent
      self.update_column(:root_parent_id, find_root_parent.id)
    end
  end

  # catchall publish method that handles interacting w/ the publish record
  def publish!
    update_attribute published: true
  end

  # for threaded contents
  # returns the original content of the thread by recursively iterating through parent
  # association
  def find_root_parent
    if parent.present?
      parent.find_root_parent
    else
      self
    end
  end

  # return ordered hash of downstream thread
  def get_downstream_thread
    if children.present?
      children_hash = {}
      children.each do |c|
        children_hash[c.id] = c.get_downstream_thread
      end
      children_hash
    else
      nil
    end
  end

  # return thread of comment-type objects associated with self
  # NOTE: for simplicity, I'm ignoring tiers of comments here. We'll still return them...
  # but until told otherwise, this is the way we're doing it because it's much easier.
  def get_comment_thread(tier=0)
    if children.present?
      comments = []
      children.order('pubdate ASC').each do |c|
        if c.channel_type == 'Comment'
          c.tier = tier
          comments += [c]
          comments += c.get_comment_thread(tier+1)
        end
      end
      comments
    else
      []
    end
  end

  ################
  # Not currently used.  Maybe in the future? if not, then remove
=begin
  def get_ordered_downstream_thread(tier=0)
    downstream_thread = []
    if children.present?
      children.each do |c|
        downstream_thread << [c.id, tier+1]
        children2 = c.get_ordered_downstream_thread(tier+1)
        downstream_thread += children2 if children2.present?
      end
    end
    if downstream_thread.empty?
      nil
    else
      downstream_thread
    end
  end
=end

  # used for the DSP to determine whether there is a promotion banner
  def has_active_promotion?
    PromotionBanner.for_content(id).active.count > 0
  end

  def has_active_promotion
    has_active_promotion?
  end

  def has_paid_promotion?
    PromotionBanner.for_content(id).paid.count > 0
  end

  def has_paid_promotion
    has_paid_promotion?
  end

  def has_promotion_inventory?
    PromotionBanner.for_content(id).has_inventory.count > 0
  end

  def has_promotion_inventory
    has_promotion_inventory?
  end

  # cleans raw_content for text emails
  #
  # @return string with HTML tags and escaped spaces (&nbsp;) removed and hyperlinks changed to text surrounded by ()
  def raw_content_for_text_email
    return raw_content if raw_content.nil?

    # strip HTML comments. meta, style and cdata tags (this is where Microsoft puts a whole bunch of crud that
    # users cut and paste)
    #
    # Test data:
    #
    # 20150923 test content IDS: 784073 784727 784766 784934 786634 787513 788246 788798 788801 791517 792174 793240
    #                            793719 793994
    # MySQL query: SELECT * FROM contents WHERE DATE(pubdate) > DATE("2015-08-01") AND raw_content LIKE "%gte mso 9%" AND channel_type IS NOT NULL;
    doc = Nokogiri::HTML::fragment(CGI::unescapeHTML(raw_content))
    doc.traverse do |node|
      node.remove if %w(comment meta style #cdata-section).include? node.name
    end
    clean_content = doc.to_html

    # strip all tags but <p>, <br> and <a> and their href attributes and clean up &nbsp; and &amp;
    text = sanitize(clean_content, {tags: %w(a p br), attributes: %w(href)}).gsub(/&nbsp;/, ' ').gsub(/&amp;/,'&')

    # now convert all the p and br tags to newlines, then squeeze big sets (>3) of contiguous newlines down to just two.
    text = text.gsub(/\<\/p\>\<p\>/,"\n").gsub(/\<p\>/,"\n").gsub(/\<br\>/,' ').gsub(/\<\/p\>/,"\n").squeeze("\n") #.gsub(/^\n{2,}/m,"\n\n") #.squeeze("\n")

  end

  # Creates sanitized version of title - at this point, just stripping out listerv towns
  def sanitized_title
    if title.present?
      new_title = title.gsub(/\[[^\]]+\]/, "").strip
      new_title.present? ? new_title : "Post by #{author_name}"
    else
      nil
    end
  end

  # Creates HTML-annotated, sanitized version of the raw_content that should be
  # as display-ready as possible
  def sanitized_content
    if raw_content.nil?
      raw_content
    elsif origin == UGC_ORIGIN
      ugc_sanitized_content
    else
      default_sanitized_content
    end
  end

  def ugc_sanitized_content
    UgcSanitizer.call(raw_content)
  end

  def default_sanitized_content
    pre_sanitize_filters = [
      # HACK: not sure exactly what this is...
      #[:gsub!, ["\u{a0}",""]], # get rid of... this
      [:gsub!, [/<!--(?:(?!-->).)*-->/m, ""]], # get rid of HTML comments
      [:gsub!, [/<![^>]*>/, ""]], # get rid of doctype
      [:gsub!, [/<\/div><div[^>]*>/, "\n\n"]], # replace divs with new lines
    ]

    # fix state abbreviations from N.y. to N.Y.
    c = raw_content.gsub(/[[:alpha:]]\.[[:alpha:]]\./) {|s| s.upcase }
    pre_sanitize_filters.each {|f| c.send f[0], *f[1]}
    doc =  Nokogiri::HTML.parse(c)

    doc.search("style").each {|t| t.remove() }
    doc.search('//text()').each {|t| t.content = t.content.sub(/^[^>\n]*>\p{Space}*\z/, "") } # kill tag fragments
    is_newline = Proc.new do |t|
      not t.nil? and (t.matches? "br" or (t.matches? "p" and t.children.empty?))
    end
    remove_dup_newlines = Proc.new do |this_e, &block|
      while is_newline.call(this_e.next())
        block.call() if block
        this_e.next().remove()
      end
    end

    #for removing br tags at specific places
    remove_br_tags = Proc.new do |node|
      node.gsub /<\s?br\s?\/?\s?>/i, ''
    end

    #replace all span elements with their content
    doc.traverse do |node|
      node.replace node.inner_html if node.name == 'span'
    end
    doc.search("p").each do |e|
      # This removes completely empty <p> tags... hopefully helps with excess whitespace issues
      if e.children.empty?
        e.remove
      # We saw content where only a text fragment was inside a "<p>" block, but then the following
      # tags "really" should have been part of that initial text fragment. This logic attempts to
      # remove excess whitespace in that and consolidate into 1 or more <p> blocks.
      else
        text = [remove_br_tags.call(e.inner_html)]
        next_e = e.next()
        until next_e.nil? do
          if next_e.text?
            text[-1] += remove_br_tags.call(next_e.inner_html)
          elsif is_newline.call(next_e)
            remove_dup_newlines.call(next_e)
          elsif next_e.matches? "strong"
            text.append "" if is_newline.call(next_e.next())
            text[-1] += " " if text[-1][-1] != " "
            text[-1] += next_e.to_html unless next_e.children.empty?
          else
            break
          end
          this_e = next_e
          next_e = next_e.next()
          this_e.remove()
        end
        text = text.delete_if {|t| t.empty? or t.blank?}
        new_node = Nokogiri::HTML.fragment("<p>#{text.shift}</p>")
        begin
          e = e.replace(new_node)
        rescue ArgumentError
          logger.warn("failed to replace some <p> tags for #{id}")
        end
        text.reverse_each { |t| e.after("<p>#{t}</p>") }
      end
    end
    # try to remove any lingering inline CSS or bad text
    e_iter = doc.search("body").first.children.first unless doc.search("body").first.nil?
    until e_iter.nil? do
      if e_iter.text?
        e_iter.remove() if e_iter.text.match(/\A.*{.*}\Z/) or e_iter.text.blank?
      elsif e_iter.matches? "br"
      else
      end
      e_iter = e_iter.next()
    end

    # Get rid of excess whitespace caused by a ton of <br> tags
    doc.search("br").each {|e| remove_dup_newlines.call(e) }
    c = doc.search("body").first.to_html unless doc.search("body").first.nil?
    c ||= doc.to_html
    c = sanitize(c, tags: %w(span div img a p br h1 h2 h3 h4 h5 h6 strong em table td tr th ul ol li b i u iframe))
    c = simple_format c, {},  sanitize: false
    c.gsub!(/(<a href="http[^>]*)>/, '\1 target="_blank">')

    BLACKLIST_BLOCKS.each do |b|
      if /^\/(.*)\/([a-z]*)$/ =~ b.strip
        match = $~
        opts = 0
        match[2].each_char do |flag|
          case flag
          when "i"
            opts |= Regexp::IGNORECASE
          when "m"
            opts |= Regexp::MULTILINE
          when "x"
            opts |= Regexp::EXTENDED
          end
        end
        b = Regexp.new match[1], opts
      else
        b = b.strip
      end
      c.gsub!(b, "")
    end

    c.gsub!(/(?:[\n]+|<br(?:\ \/)?>|<p>(?:[\n]+|<br(?:\ \/)?>|[\s]+|[[:space:]]+|(?:\&#160;)+)?<\/p>)(?:[\n]+|<br(?:\ \/)?>|<p>(?:[\n]+|<br(?:\ \/)?>|[\s]+|[[:space:]]+|(?:\&#160;)+)?<\/p>)+/m, "<br />")
    c.gsub!(/(?:[\n]+|<br(?:\ \/)?>|<p>(?:[\n]+|<br(?:\ \/)?>|[\s]+|[[:space:]]+|(?:\&#160;)+)?<\/p>)(?:[\n]+|<br(?:\ \/)?>|<p>(?:[\n]+|<br(?:\ \/)?>|[\s]+|[[:space:]]+|(?:\&#160;)+)?<\/p>)+/m, "")

    # remove non-UTF-8 content - in Rails 3 you have to transcode to some other then recode to UTF-8
    # in Rails 4, use ActiveSupport's scrub()
    Rinku.auto_link c #.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
  end

  def sanitized_content= new_content
    self.raw_content = new_content
  end

  # removes boilerplate
  def remove_boilerplate
    return raw_content if raw_content.nil?

    c = raw_content

    BLACKLIST_BLOCKS.each do |b|
      if /^\/(.*)\/([a-z]*)$/ =~ b.strip
        match = $~
        opts = 0
        match[2].each_char do |flag|
          case flag
            when "i"
              opts |= Regexp::IGNORECASE
            when "m"
              opts |= Regexp::MULTILINE
            when "x"
              opts |= Regexp::EXTENDED
          end
        end
        b = Regexp.new match[1], opts
      else
        b = b.strip
      end
      c.gsub!(b, "")
    end

    c.gsub!(/(?:[\n]+|<br(?:\ \/)?>|<p>(?:[\n]+|<br(?:\ \/)?>|[\s]+|[[:space:]]+|(?:\&#160;)+)?<\/p>)(?:[\n]+|<br(?:\ \/)?>|<p>(?:[\n]+|<br(?:\ \/)?>|[\s]+|[[:space:]]+|(?:\&#160;)+)?<\/p>)+/m, "<br />")
    c.gsub(/(?:[\n]+|<br(?:\ \/)?>|<p>(?:[\n]+|<br(?:\ \/)?>|[\s]+|[[:space:]]+|(?:\&#160;)+)?<\/p>)(?:[\n]+|<br(?:\ \/)?>|<p>(?:[\n]+|<br(?:\ \/)?>|[\s]+|[[:space:]]+|(?:\&#160;)+)?<\/p>)+/m, "")

  end

  # returns true if content has attached event
  def is_event?
    channel_type.present? and channel_type == "Event"
  end

  def is_market_post?
    channel_type.present? and channel_type == "MarketPost"
  end

  def is_campaign?
    content_category_id == ContentCategory.find_or_create_by(name: 'campaign').id
  end

  # Retrieves similar content (as configured in similar_content_overrides for sponsored content or determined by
  # ElasticSearch similarity and returns array of related content objects
  #
  # @param num_similar [Integer] number of results to return
  # @return [Array<Content>] list of similar content
  def similar_content(num_similar)
    c = self.similar(
      fields: [:title, :content, :location_id],
      where: {
        pubdate: 5.years.ago..Time.current,
        removed: { not: true },
        has_future_event_instance: { not: false },
        channel_type: { not: 'Comment' },
        origin: UGC_ORIGIN
      },
      load: false,
      limit: num_similar
    )
    c
  end

  def uri
    CGI.escape(BASE_URI + "/#{id}")
  end


  def talk_comments
    children.where(root_content_category_id: [ContentCategory.find_by_name('discussion'), ContentCategory.find_by_name('talk_of_the_town').id])
  end

  def is_sponsored_content?
    content_category.name == 'sponsored_content'
  end

  def increment_view_count!
    # check if content is published before incrementing
    if self.published
      unless User.current.try(:skip_analytics) && root_content_category.name == "news"
        increment_integer_attr!(:view_count)
      end
    end
  end

  #returns the URI path that matches UX2 for this content record
  def ux2_uri
    return "" unless root_content_category.present?
    prefix = root_content_category.try(:name)
    # convert talk_of_the_town to talk
    prefix = 'talk' if prefix == 'talk_of_the_town'
    "/#{prefix}/#{id}"
  end

  # boolean represents whether the record has associated metrics reports
  def has_metrics_reports?
    content_reports.present?
  end

  # draft management methods
  #
  # contents can have three states:
  # -- draft: saved, but not published to DSP and not returned in any API responses
  #           except dashborad)
  # -- scheduled: saved, pubdate in the future, published to the DSP, but not returned
  #           in API responses except dashboard *until* Time.current > pubdate
  # -- published: normal published state. Exists in DSP, returned in API responses.
  #
  # there's the potential to implement this with a state_machine gem in the future,
  # especially if it gets more complex. For now, we're just emulating that behavior
  # as minimally as possible.

  # typically returns author information by checking `created_by` if available
  # or falling back to `authors` otherwise. For UGC News content, we reverse the conditional.
  #
  # @return [String] the author's name
  def author_name
    if is_news_ugc? || is_news_child_category?
      if authors_is_created_by?
        created_by.try(:name)
      else
        authors
      end
    else
      created_by.present? ? created_by.name : authors
    end
  end

  # helper that checks if content is News UGC or not
  #
  # @return [Boolean] true if is news ugc
  def is_news_ugc?
    origin == UGC_ORIGIN and content_category.try(:name) == 'news'
  end

  def is_news_child_category?
    root_content_category.try(:name) == 'news'
  end

  def current_daily_report(current_date=Date.current)
    content_reports.where("report_date >= ?", current_date).take
  end

  def find_or_create_daily_report(current_date=Date.current)
    current_daily_report(current_date) || content_reports.create!(report_date: current_date)
  end

  def ok_to_send_alert?
    self.created_by&.receive_comment_alerts && created_by.present?
  end

  def embedded_ad?
    !!(organization.present? && organization.embedded_ad)
  end

  def should_notify_subscribers?
    organization&.subscribe_url.present? &&
      !outside_subscriber_notification_blast_radius? &&
      (is_not_campaign? || is_feature_notification?)
  end

  private

  def require_at_least_one_content_location
    unless content_locations.any?
      errors.add(:content_locations, "must have at least one location")
    end
  end

  def if_ad_promotion_type_sponsored_must_have_ad_max_impressions
    if ad_promotion_type == PromotionBanner::SPONSORED && ad_max_impressions.nil?
      errors.add(:ad_max_impressions, "For ad_promotion_type Sponsored, ad_max_impressions must be populated")
    end
  end

  def is_not_campaign?
    [:news, :event, :talk, :market].include?(content_type)
  end

  def is_feature_notification?
    !!organization&.feature_notification_org?
  end

  ORGANIZATIONS_NOT_FOR_AUTOMATIC_SUBSCRIBER_ALERTS = [
    "Dev Testbed",        # For testing on an FE
  ]

  def outside_subscriber_notification_blast_radius?
    ORGANIZATIONS_NOT_FOR_AUTOMATIC_SUBSCRIBER_ALERTS.include?(organization_name)
  end

  def hide_campaign_from_public_view
    if root_content_category_id == ContentCategory.find_or_create_by(name: 'campaign').id
      update_attribute(:biz_feed_public, false)
    end
  end
end
