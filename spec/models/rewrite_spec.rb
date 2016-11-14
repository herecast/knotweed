# == Schema Information
#
# Table name: rewrites
#
#  id          :integer          not null, primary key
#  source      :string(255)
#  destination :string(255)
#  created_by  :integer
#  updated_by  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
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
