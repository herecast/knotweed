# frozen_string_literal: true

# == Schema Information
#
# Table name: business_profiles
#
#  id                   :bigint(8)        not null, primary key
#  business_location_id :bigint(8)
#  has_retail_location  :boolean          default(TRUE)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  source               :string(255)
#  source_id            :string(255)
#  existence            :float
#  archived             :boolean          default(FALSE)
#
# Indexes
#
#  idx_16451_index_business_profiles_on_existence             (existence)
#  idx_16451_index_business_profiles_on_source_and_source_id  (source,source_id)
#

class BusinessProfile < ActiveRecord::Base
  searchkick locations: ['location'], callbacks: :async, batch_size: 1000,
             index_prefix: Figaro.env.searchkick_index_prefix, match: :word_start,
             searchable: %i[title content business_location_name
                            business_location_city]

  def search_data
    index = {
      archived: archived,
      exists: (existence.nil? || (existence >= 0.4))
    }
    if content.present?
      index = index.merge(
        title: content.title,
        content: strip_tags(content.raw_content),
        organization_id: content.organization_id
      )
    end
    if business_location.present?
      index = index.merge(
        business_location_name: business_location.name,
        business_location_city: business_location.city,
        business_location_state: business_location.state,
        location: { lat: business_location.latitude, lon: business_location.longitude }
      )
    end
    index
  end

  scope :search_import, lambda {
    includes(:content,
             :business_location)
      .where('archived = false')
  }

  def should_index?
    archived == false
  end

  has_one :content, as: :channel, dependent: :destroy
  accepts_nested_attributes_for :content
  validates_associated :content

  after_commit :reindex_organization
  def reindex_organization
    if content.present? && organization.present?
      organization.reindex
    end
  end

  after_destroy do
    if content.present?
      organization.destroy if organization.present? && (organization.contents.count == 0)
    end
  end

  belongs_to :business_location, dependent: :destroy
  accepts_nested_attributes_for :business_location

  delegate :organization, to: :content

  def claimed?
    content.present? && organization.present?
  end

  private

  # helper method that standardizes hours strings
  #
  # @param hours [String] the hour string
  # @param format [String] the incoming data format
  #
  # @return hours [Array] array of strings representing the hour information
  def self.convert_hours_to_standard(hours, format = nil)
    output = hours.strip
    if format == 'factual'
      output.gsub!(/Mon|Tue|Wed|Thu|Fri|Sat|Sun|Open Daily/,
                   'Mon' => 'Mo',
                   'Tue' => 'Tu',
                   'Wed' => 'We',
                   'Thu' => 'Th',
                   'Fri' => 'Fr',
                   'Sat' => 'Sa',
                   'Sun' => 'Su',
                   'Open Daily' => 'Mo-Su')
      # convert all "8:00" style hour definitions to "08:00"
      output.gsub!(/([ \-])(\d:\d{2})/, '\\10\\2')

      # convert 12:00 AM (midnight) to 00:00
      output.gsub!('12:00 AM', '00:00')

      # get rid of AM references
      output.gsub!(' AM', '')

      output.gsub! /(\d{1,2}):(\d{2}) PM/ do |_str|
        # "12:00 PM" is noon, which we don't want to convert to 24:00 / 0:00
        hour = (Regexp.last_match(1) != '12' ? Regexp.last_match(1).to_i + 12 : Regexp.last_match(1))
        "#{hour}:#{Regexp.last_match(2)}"
      end

      # if the timing extends beyond midnight, Factual includes two sets of hours
      # separated by a comma
      split_by_comma = output.split(',')
      if split_by_comma.count > 1
        day_string = split_by_comma[0].match(/\w{2}-\w{2}/)[0]
        output = [split_by_comma[0], "#{day_string}|#{split_by_comma[1].strip}"]
      else
        output = [output]
      end

      # change day-time space divider to '|'
      output.map! { |o| o.tr(' ', '|') }
    end
    output
  end
end
