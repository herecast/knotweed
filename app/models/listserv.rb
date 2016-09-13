# == Schema Information
#
# Table name: listservs
#
#  id                          :integer          not null, primary key
#  name                        :string(255)
#  reverse_publish_email       :string(255)
#  import_name                 :string(255)
#  active                      :boolean
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  digest_send_time            :time
#  unsubscribe_email           :string(255)
#  post_email                  :string(255)
#  subscribe_email             :string(255)
#  mc_list_id                  :string(255)
#  mc_segment_id               :string(255)
#  send_digest                 :boolean          default(FALSE)
#  last_digest_send_time       :datetime
#  last_digest_generation_time :datetime
#  digest_header               :text(65535)
#  digest_footer               :text(65535)
#  digest_send_description     :text
#  digest_send_day             :integer
#

class Listserv < ActiveRecord::Base
  has_many :promotion_listservs
  has_and_belongs_to_many :locations
  has_many :subscriptions

  validates_uniqueness_of :reverse_publish_email, :unsubscribe_email,
    :subscribe_email, :post_email, allow_blank: true

  validates :reverse_publish_email, absence: { absence: true,
    message: "Can't populate `reverse_publish_email` for lists that are managed by Subtext." },
    if: :is_managed_list?
  validates :unsubscribe_email, :subscribe_email, :post_email, absence: { absence: true,
    message: "Can't populate these fields for lists that are managed by Vital Communities." },
    if: :is_vc_list?

  validates :digest_reply_to, presence: true, if: :send_digest?
  validates :digest_send_time, presence: true, if: :send_digest?

  validate :no_altering_queries
  validate :valid_template_name

  default_scope { where active: true }

  def active_subscriber_count
    subscriptions.active.count
  end

  # Sends the content to this listserv using ReversePublishMailer
  def send_content_to_listserv(content, consumer_app=nil)
    outbound_mail = ReversePublisher.mail_content_to_listservs(content, [self], consumer_app)
    outbound_mail.deliver_later
    ReversePublisher.send_copy_to_sender_from_dailyuv(content, outbound_mail.text_part.body.to_s, outbound_mail.html_part.body.to_s).deliver_later
    add_listserv_location_to_content(content)
  end

  def add_listserv_location_to_content(content)
    if self.locations.present?
      self.locations.each do |l|
        content.locations << l unless content.locations.include? l
      end
    end
  end

  def is_managed_list?
    subscribe_email.present? or post_email.present? or unsubscribe_email.present?
  end

  def is_vc_list?
    reverse_publish_email.present?
  end

  def no_altering_queries
    if self.digest_query?
      query_array = self.digest_query.upcase.split(' ')
      reserved_commands = %w(INSERT UPDATE DELETE DROP TRUNCATE)
      has_reserved_words = query_array.any? { |word| reserved_commands.include?(word) }
      errors.add(:digest_query, "Commands to alter data are not allowed") if has_reserved_words
    end
  end

  def valid_template_name
    if self.template? and digest_templates.exclude? self.template
      errors.add(:template, "Please enter a valid template")
    end
  end

  def next_digest_send_time
    if digest_send_time? && !digest_send_day?
      tm = parse_digest_send_time
      tm.future? ? tm : tm.tomorrow
    elsif digest_send_time? && digest_send_day?
      tm = parse_digest_send_time
      time_with_week = tm.next_week(digest_days_as_symbol)
      find_week_to_send(time_with_week)
    end
  end

  def banner_ad
    PromotionBanner.find(self.banner_ad_override_id) if banner_ad_override_id.present?
  end 

  def digest_days_as_symbol
    self.digest_send_day.downcase.to_sym
  end

  def self.digest_days
    [
      "Sunday",
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
    ]
  end

  def content_ids_for_results
    custom_digest_results.map { |result| result[:id] }
  end

  private

  def parse_digest_send_time
    Time.zone.parse(digest_send_time.strftime("%H:%M"))
  end

  def find_week_to_send(time_with_week)
    if time_with_week > 1.week.from_now
      time_with_week = time_with_week.advance(weeks: -1)
    else
      time_with_week
    end
  end

  def get_query
    ActiveRecord::Base.connection.execute(self.digest_query)
  end

  def custom_digest_results
    records = get_query
    #retuns columns for query
    fields = records.fields
    #combines column name with value into array
    #[[column_name, value], [column_name, value]]
    zipped_results = records.map { |record| fields.zip(record) }
    #convert results to hash_with_different_access
    zipped_results.map do |array|
      ActiveSupport::HashWithIndifferentAccess.new(array.to_h)
    end
    #retuns array wwith results as hash
    #[{'id' => 1 }, {'id' => 2}]
  end
  
  def digest_templates
    templates = Dir.entries('app/views/listserv_digest_mailer/')
    file_names = templates.map { |file| file.split('.').first }
    file_names.compact!
  end
end
