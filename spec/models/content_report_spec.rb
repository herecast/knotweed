require 'spec_helper'

describe ContentReport do
  before { @content_report = FactoryGirl.build :content_report }
  subject { @content_report }
  it { should be_valid }
end
