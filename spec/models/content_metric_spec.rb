# == Schema Information
#
# Table name: content_metrics
#
#  id                 :integer          not null, primary key
#  content_id         :integer
#  event_type         :string
#  user_id            :integer
#  user_agent         :string
#  user_ip            :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  client_id          :string
#  location_id        :integer
#  organization_id    :integer
#  location_confirmed :boolean          default(FALSE)
#
# Indexes
#
#  index_content_metrics_on_client_id        (client_id)
#  index_content_metrics_on_content_id       (content_id)
#  index_content_metrics_on_event_type       (event_type)
#  index_content_metrics_on_location_id      (location_id)
#  index_content_metrics_on_organization_id  (organization_id)
#  index_content_metrics_on_user_id          (user_id)
#

require 'rails_helper'

RSpec.describe ContentMetric, type: :model do
  it { is_expected.to belong_to :location }
  it { is_expected.to belong_to :user }
  it { is_expected.to belong_to :content }

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

  describe "#organization" do
    it { is_expected.to belong_to :organization }

    let(:organization) {
      FactoryGirl.create :organization
    }

    let!(:content) {
      FactoryGirl.create :content,
                         organization: organization
    }

    context 'creating a new record' do
      subject {
        FactoryGirl.create :content_metric,
                           content: content
      }

      it 'assigns organization from content record' do
        expect(subject.organization).to eql organization
      end
    end
  end
end
