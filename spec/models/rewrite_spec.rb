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
