# == Schema Information
#
# Table name: content_metrics
#
#  id         :integer          not null, primary key
#  content_id :integer
#  event_type :string
#  user_id    :integer
#  user_agent :string
#  user_ip    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'

RSpec.describe ContentMetric, type: :model do
  context "when no content_id present" do
    it "is not valid" do
      content_metric = FactoryGirl.build :content_metric, content_id: nil
      expect(content_metric).not_to be_valid
    end
  end

  context "when content_id present" do
    it "is valid" do
      content_metric = FactoryGirl.build :content_metric, content_id: 1
      expect(content_metric).to be_valid
    end
  end
end