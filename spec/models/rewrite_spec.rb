# frozen_string_literal: true
# == Schema Information
#
# Table name: rewrites
#
#  id            :bigint(8)        not null, primary key
#  source        :string(255)
#  destination   :string(255)
#  created_by_id :bigint(8)
#  updated_by_id :bigint(8)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  idx_16828_index_rewrites_on_created_by  (created_by_id)
#  idx_16828_index_rewrites_on_source      (source) UNIQUE
#  idx_16828_index_rewrites_on_updated_at  (updated_at)
#

require 'spec_helper'

describe Rewrite, type: :model do
  before do
    @source = 'NeVer-LanD'
    @rewrite = FactoryGirl.create :rewrite, source: @source
  end

  it 'should save the source in lowercase' do
    expect(@rewrite.reload.source).to eq @source.downcase
  end
end
