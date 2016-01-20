# == Schema Information
#
# Table name: content_sets
#
#  id                    :integer          not null, primary key
#  import_method         :string(255)
#  import_method_details :text
#  organization_id       :integer
#  name                  :string(255)
#  description           :text
#  notes                 :text
#  status                :string(255)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  start_date            :date
#  end_date              :date
#  ongoing               :boolean
#  format                :string(255)
#  publishing_frequency  :string(255)
#  developer_notes       :text
#  import_priority       :integer          default(1)
#  import_url_path       :string(255)
#

require 'spec_helper'

describe ContentSet do
  describe "set_publishing_frequency" do
    it "should do nothing if publishing_frequency is set" do
      pub = FactoryGirl.create(:publication, publishing_frequency: Publication::FREQUENCY_OPTIONS[0])
      cset = FactoryGirl.create(:content_set, publishing_frequency: Publication::FREQUENCY_OPTIONS[1], publication: pub)
      cset.publishing_frequency.should == Publication::FREQUENCY_OPTIONS[1]
      cset.publishing_frequency.should_not == pub.publishing_frequency
    end
    it "should set publishing_frequency to its publication's if it is not set" do
      pub = FactoryGirl.create(:publication, publishing_frequency: Publication::FREQUENCY_OPTIONS[0])
      cset = FactoryGirl.create(:content_set, publication: pub)
      cset.publishing_frequency.should == Publication::FREQUENCY_OPTIONS[0]
      cset.publishing_frequency.should == pub.publishing_frequency
    end
  end
      
end
