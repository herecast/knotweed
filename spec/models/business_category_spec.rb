# == Schema Information
#
# Table name: business_categories
#
#  id          :bigint(8)        not null, primary key
#  name        :string(255)
#  description :string(255)
#  icon_class  :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  source      :string(255)
#  source_id   :bigint(8)
#
# Indexes
#
#  idx_16420_index_business_categories_on_source_and_source_id  (source,source_id)
#

require 'spec_helper'

describe BusinessCategory, :type => :model do
  describe '#full_descendant_ids' do
    before do
      @root = FactoryGirl.create :business_category
      @t1_1 = FactoryGirl.create :business_category, parents: [@root]
      @t2_1 = FactoryGirl.create :business_category, parents: [@t1_1]
      @t2_2 = FactoryGirl.create :business_category, parents: [@t1_1]
      @t1_2 = FactoryGirl.create :business_category, parents: [@root]
    end

    it { expect(@root.full_descendant_ids).to match_array([@root.id, @t1_1.id, @t2_1.id, @t2_2.id, @t1_2.id]) }
    it { expect(@t1_1.full_descendant_ids).to match_array([@t1_1.id, @t2_1.id, @t2_2.id]) }
    it { expect(@t1_2.full_descendant_ids).to match_array([@t1_2.id]) }
    it { expect(@t2_1.full_descendant_ids).to match_array([@t2_1.id]) }

  end
end
