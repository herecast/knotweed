# == Schema Information
#
# Table name: rewrites
#
#  id            :integer          not null, primary key
#  source        :string(255)
#  destination   :string(255)
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  idx_16828_index_rewrites_on_created_by  (created_by)
#  idx_16828_index_rewrites_on_source      (source) UNIQUE
#  idx_16828_index_rewrites_on_updated_at  (updated_at)
#

require 'spec_helper'


describe Rewrite, :type => :model do
  before do
    @source = 'NeVer-LanD'
    @rewrite = FactoryGirl.create :rewrite, source: @source
  end

  it 'should save the source in lowercase' do
    expect(@rewrite.reload.source).to eq  @source.downcase
  end

end
