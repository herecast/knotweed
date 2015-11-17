require 'spec_helper'

describe ContentReports do
  before { @content_report = FactoryGirl.create :content_report }
  subject { @content_report }
  it { should be_valid }
end
