# == Schema Information
#
# Table name: issues
#
#  id                 :integer          not null, primary key
#  issue_edition      :string(255)
#  organization_id    :integer
#  copyright          :string(255)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  import_location_id :integer
#  publication_date   :datetime
#

require 'spec_helper'

describe Issue do
  before do
  	@issue = FactoryGirl.create :issue, issue_edition: 'defacto name'
  end

  describe "#name" do
  	it "returns :issue_edition as name" do
  		expect(@issue.name).to eq 'defacto name'
  	end
  end
end
