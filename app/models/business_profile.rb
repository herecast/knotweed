# == Schema Information
#
# Table name: business_profiles
#
#  id                        :integer          not null, primary key
#  business_location_id      :integer
#  has_retail_location       :boolean          default(TRUE)
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  source                    :string(255)
#  source_id                 :string(255)
#  existence                 :float
#  feedback_count            :integer          default(0)
#  feedback_recommend_avg    :float            default(0.0)
#  feedback_price_avg        :float            default(0.0)
#  feedback_satisfaction_avg :float            default(0.0)
#  feedback_cleanliness_avg  :float            default(0.0)
#  archived                  :boolean          default(FALSE)
#

class BusinessProfile < ActiveRecord::Base

  searchkick locations: ['location'], callbacks: :async, batch_size: 100,
    index_prefix: Figaro.env.searchkick_index_prefix, match: :word_start,
    searchable: [:category_names, :title, :content, :business_location_name,
                 :business_location_city]

  def search_data
    index = {
      category_names: business_categories.map(&:name),
      category_ids: business_categories.map(&:id),
      feedback_count: feedback_count,
      feedback_satisfaction_avg: feedback_satisfaction_avg,
      feedback_price_avg: feedback_price_avg,
      feedback_recommend_avg: feedback_recommend_avg,
      feedback_cleanliness_avg: feedback_cleanliness_avg,
      archived: archived,
      exists: (existence.nil? or existence >= 0.4)
    }
    if content.present?
      index.merge!({
        title: content.title,
        content: strip_tags(content.raw_content),
        organization_id: content.organization_id
      })
    end
    if business_location.present?
      index.merge!({
        business_location_name: business_location.name,
        business_location_city: business_location.city,
        business_location_state: business_location.state,
        location: { lat: business_location.latitude, lon: business_location.longitude }
      })
    end
    index
  end

  has_one :content, as: :channel, dependent: :destroy
  accepts_nested_attributes_for :content
  validates_associated :content

  after_destroy do
    if content.present?
      organization.destroy if organization.present? and organization.contents.count == 0
    end
  end

  belongs_to :business_location, dependent: :destroy
  accepts_nested_attributes_for :business_location

  delegate :organization, to: :content

  has_and_belongs_to_many :business_categories, join_table: 'business_categories_business_profiles', after_add: :reindex_business_profile

  def reindex_business_profile(business_category)
    reindex_async
  end

  has_many :business_feedbacks, dependent: :destroy

  def claimed?
    content.present? && organization.present?
  end

  def update_feedback_cache!
    fb = feedback_calc # cache db call
    self.feedback_price_avg = fb[:price]
    self.feedback_recommend_avg = fb[:recommend]
    self.feedback_satisfaction_avg = fb[:satisfaction]
    self.feedback_cleanliness_avg = fb[:cleanliness]
    self.feedback_count = business_feedbacks.size
    save!(validate: false)
  end

  private
  # returns hash of aggregated feedbacks
  #
  # @return [Hash] average feedback values
  def feedback_calc
    averages = business_feedbacks.order('').select('AVG(CAST(satisfaction AS INTEGER)) sat, AVG(CAST(cleanliness AS INTEGER)) cle,' +
                                         'AVG(CAST(price AS INTEGER)) pri, AVG(CAST(recommend AS INTEGER)) rec').first
    {
      satisfaction: averages.sat,
      cleanliness: averages.cle,
      price: averages.pri,
      recommend: averages.rec
    }
  end

  # helper method that standardizes hours strings
  #
  # @param hours [String] the hour string
  # @param format [String] the incoming data format
  #
  # @return hours [Array] array of strings representing the hour information
  def self.convert_hours_to_standard(hours, format=nil)
    output = hours.strip
    if format == 'factual'
      output.gsub!(/Mon|Tue|Wed|Thu|Fri|Sat|Sun|Open Daily/, {
        'Mon' => 'Mo',
        'Tue' => 'Tu',
        'Wed' => 'We',
        'Thu' => 'Th',
        'Fri' => 'Fr',
        'Sat' => 'Sa',
        'Sun' => 'Su',
        'Open Daily' => 'Mo-Su'
      })
      # convert all "8:00" style hour definitions to "08:00"
      output.gsub!(/([ \-])(\d:\d{2})/, "\\10\\2")

      # convert 12:00 AM (midnight) to 00:00
      output.gsub!('12:00 AM', '00:00')

      # get rid of AM references
      output.gsub!(' AM', '')

      output.gsub! /(\d{1,2}):(\d{2}) PM/ do |str|
        # "12:00 PM" is noon, which we don't want to convert to 24:00 / 0:00
        hour = ($1 != '12' ? $1.to_i + 12 : $1)
        "#{hour}:#{$2}"
      end

      # if the timing extends beyond midnight, Factual includes two sets of hours
      # separated by a comma
      split_by_comma = output.split(",")
      if split_by_comma.count > 1
        day_string = split_by_comma[0].match(/\w{2}-\w{2}/)[0]
        output = [split_by_comma[0], "#{day_string}|#{split_by_comma[1].strip}"]
      else
        output = [output]
      end

      # change day-time space divider to '|'
      output.map!{|o| o.gsub(' ', '|')}
    end
    output
  end
end
