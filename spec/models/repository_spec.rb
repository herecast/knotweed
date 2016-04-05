# == Schema Information
#
# Table name: repositories
#
#  id                      :integer          not null, primary key
#  name                    :string(255)
#  dsp_endpoint            :string(255)
#  sesame_endpoint         :string(255)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  graphdb_endpoint        :string(255)
#  annotate_endpoint       :string(255)
#  solr_endpoint           :string(255)
#  recommendation_endpoint :string(255)
#

require 'spec_helper'

describe Repository do
  before do
    # this is to account for differences between default environment repos
    FactoryGirl.create :repository, id: 3
    FactoryGirl.create :repository, id: 6
  end

  describe "::production_repo" do
    it "returns production repository" do
      expect(Repository.production_repo).to be_a Repository
    end
  end
end
