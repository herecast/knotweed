# == Schema Information
#
# Table name: profile_metrics
#
#  id                 :integer          not null, primary key
#  organization_id    :integer
#  location_id        :integer
#  user_id            :integer
#  content_id         :integer
#  event_type         :string
#  user_ip            :string
#  user_agent         :string
#  client_id          :string
#  location_confirmed :boolean
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

require 'rails_helper'

RSpec.describe ProfileMetric, type: :model do
  it { is_expected.to belong_to(:organization) }
  it { is_expected.to belong_to(:location) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to have_db_column(:client_id).of_type(:string) }
  it { is_expected.to have_db_column(:user_ip).of_type(:string) }
  it { is_expected.to have_db_column(:user_agent).of_type(:string) }
  it { is_expected.to have_db_column(:location_confirmed).of_type(:boolean) }

  context 'with event_type equal to "click"' do
    before do
      subject.event_type = 'click'
    end

    it 'requires content_id' do
      subject.content_id = nil
      subject.valid?

      expect(subject.errors).to include(:content_id)

      subject.content = FactoryGirl.create(:content)
      subject.valid?

      expect(subject.errors).to_not include(:content_id)
    end
  end
end
