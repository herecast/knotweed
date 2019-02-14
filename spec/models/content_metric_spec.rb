# frozen_string_literal: true

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

  context 'when no content_id present' do
    it 'is not valid' do
      content_metric = FactoryGirl.build :content_metric, content_id: nil
      expect(content_metric).not_to be_valid
    end
  end

  context 'when content_id present' do
    it 'is valid' do
      content_metric = FactoryGirl.build :content_metric, content_id: 1
      expect(content_metric).to be_valid
    end
  end

  describe '#organization' do
    it { is_expected.to belong_to :organization }

    let(:organization) do
      FactoryGirl.create :organization
    end

    let!(:content) do
      FactoryGirl.create :content,
                         organization: organization
    end

    context 'creating a new record' do
      subject do
        FactoryGirl.create :content_metric,
                           content: content
      end

      it 'assigns organization from content record' do
        expect(subject.organization).to eql organization
      end
    end
  end

  describe '#views_by_user_and_period' do
    let(:period_start) { 1.week.ago }
    let(:period_end) { 1.week.from_now }
    let(:user) { FactoryGirl.create :user }
    let(:org) { FactoryGirl.create :organization, pay_for_content: true }
    let(:content) { FactoryGirl.create :content, pubdate: 2.weeks.ago, created_by: user, organization: org }
    let!(:content_metrics) { FactoryGirl.create_list :content_metric, 3, content: content, event_type: 'impression' }

    subject { ContentMetric.views_by_user_and_period(period_start: period_start, period_end: period_end, user: user) }

    it 'should sum the content metric impressions matching the user\'s content' do
      expect(subject).to eq content_metrics.count
    end

    context 'for an org without pay_for_content' do
      let(:org) { FactoryGirl.create :organization, pay_for_content: false }

      it 'should be 0' do
        expect(subject).to eq 0
      end
    end
  end
end
