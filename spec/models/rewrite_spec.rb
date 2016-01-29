require 'spec_helper'


describe Rewrite do
  before do
    @source = 'NeVer-LanD'
    @rewrite = FactoryGirl.create :rewrite, source: @source
  end

  it 'should save the source in lowercase' do
    @rewrite.reload.source.should eq  @source.downcase
  end

end
