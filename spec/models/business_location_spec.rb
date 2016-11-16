# == Schema Information
#
# Table name: business_locations
#
#  id                  :integer          not null, primary key
#  name                :string(255)
#  address             :string(255)
#  phone               :string(255)
#  email               :string(255)
#  hours               :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  organization_id     :integer
#  latitude            :float
#  longitude           :float
#  venue_url           :string(255)
#  locate_include_name :boolean          default(FALSE)
#  city                :string(255)
#  state               :string(255)
#  zip                 :string(255)
#  status              :string(255)
#  created_by          :integer
#  updated_by          :integer
#  service_radius      :decimal(10, )
#

require 'spec_helper'

describe BusinessLocation, :type => :model do
  include_examples 'Auditable', BusinessLocation

  before do
	  @business_location = FactoryGirl.create :business_location
  end

  describe "#select_option_label" do
    it "returns formatted address" do
      label = @business_location.select_option_label
      expect(label).to include(@business_location.name, @business_location.address, @business_location.address, @business_location.city, @business_location.state, @business_location.zip)
    end
  end

  describe "#geocoding_address" do
    context "when the business has a name" do
      it "returns address with name" do
        @business_location.update_attribute(:locate_include_name, true)
        expect(@business_location.geocoding_address).to include(@business_location.name)
      end
    end
  end
end
