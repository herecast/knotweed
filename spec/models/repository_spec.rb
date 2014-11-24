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
  pending "add some examples to (or delete) #{__FILE__}"
end
