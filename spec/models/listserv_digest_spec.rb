# == Schema Information
#
# Table name: listserv_digests
#
#  id                   :integer          not null, primary key
#  listserv_id          :integer
#  listserv_content_ids :string
#  mc_campaign_id       :string
#  sent_at              :datetime
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  content_ids          :string
#  from_name            :string
#  reply_to             :string
#  subject              :string
#  template             :string
#  sponsored_by         :string
#  promotion_id         :integer
#  location_ids         :integer          default([]), is an Array
#  mc_segment_id        :string
#  subscription_ids     :integer          default([]), is an Array
#  title                :string
#

require 'rails_helper'

RSpec.describe ListservDigest, type: :model do
  it { is_expected.to have_db_column(:mc_campaign_id).of_type(:string) }
  it { is_expected.to have_db_column(:mc_segment_id).of_type(:string) }
  it { is_expected.to have_db_column(:sent_at).of_type(:datetime) }
  it { is_expected.to have_db_column(:listserv_content_ids).of_type(:integer) }
  it { is_expected.to have_db_column(:content_ids).of_type(:integer) }
  it { is_expected.to have_db_column(:subject).of_type(:string) }
  it { is_expected.to have_db_column(:template).of_type(:string) }
  it { is_expected.to have_db_column(:from_name).of_type(:string) }
  it { is_expected.to have_db_column(:reply_to).of_type(:string) }
  it { is_expected.to have_db_column(:sponsored_by).of_type(:string) }
  it{ is_expected.to have_db_column(:location_ids).of_type(:integer).with_options(array: true) }
  it { is_expected.to have_db_column(:title).of_type(:string) }
  it { is_expected.to have_db_column(:preheader).of_type(:string) }
  it { is_expected.to have_db_column(:promotion_ids)}

  it { is_expected.to belong_to(:listserv) }

  it { is_expected.to respond_to :listserv_contents }
  it { is_expected.to respond_to :contents }

  describe '#contents' do
    context 'after assigned and persisted' do
      let!(:contents) { FactoryGirl.create_list :content, 3 }
      let!(:digest) { FactoryGirl.create :listserv_digest, contents: contents.reverse }

      it 'returns the contents in the same order' do
        reloaded_digest = described_class.find(digest.id)
        expect(reloaded_digest.contents.first).to eql contents.reverse.first
      end
    end
  end

  describe 'locations' do
    context 'assigned an array of locations' do
      let(:locations) { FactoryGirl.create_list :location, 3 }
      before do
        subject.locations = locations
      end

      it 'assigns location_ids equal to location ids' do
        expect(subject.location_ids).to eql locations.collect(&:id)
      end
    end

    context 'assigned nil' do
      before do
        subject.locations = nil
      end

      it 'assigns location_ids to an empty array' do
        expect(subject.location_ids).to eql []
      end
    end

    context 'when location_ids holds location ids' do
      let(:locations) { FactoryGirl.create_list :location, 3 }
      before do
        subject.location_ids = locations.collect(&:id)
      end

      it 'is equal to the locations' do
        expect(subject.locations.to_a.sort_by(&:id)).to eql locations.sort_by(&:id)
      end
    end
  end

  describe '#subscriber_emails' do
    let(:subscription) { FactoryGirl.create :subscription }

    before { subject.subscription_ids = [subscription.id] }

    it 'should return the subscribers\' emails' do
      expect(subject.subscriber_emails).to match_array [subscription.email]
    end
  end

  describe '#ga_tag' do
    let(:listserv) { FactoryGirl.create :listserv }
    before do
      subject.title = "Test Listserv Digest"
      subject.listserv = listserv
    end
  
    it 'returns a google analytics tag with frequecy and date' do
      expect(subject.ga_tag).to eq "Daily_#{subject.title.gsub(' ', '_')}_#{Date.today.strftime("%m_%d_%y")}"
    end

    context 'when the digest delivers weekly' do
      before { subject.listserv.digest_send_day = "Tuesday" }

      it 'has the correct frequency' do
        expect(subject.ga_tag).to eq "Weekly_#{subject.title.gsub(' ', '_')}_#{Date.today.strftime("%m_%d_%y")}"
      end
    end

    context 'when the returned string is greater than 50 bytes' do
     before { subject.title = "Here is a super long title that will be too large formatted" }

      it 'returns a formatted string less than 50 bytes' do
        frequency = listserv.digest_send_day? ? "Weekly" : "Daily"
        formatted_title = subject.title[0, 30].gsub(' ', '_')
        expect(subject.ga_tag.bytesize).to be < 50
        expect(subject.ga_tag).to eq "#{frequency}_#{formatted_title}_#{Date.today.strftime('%m_%d_%y')}"
      end
    end
  end

  describe '#promotions' do
    let!(:promotion) { FactoryGirl.create :promotion }
    context 'when promotions are present' do
      before do
        subject.promotion_ids = [promotion.id]
      end
      it 'returns a relation of promotions' do
        expect(subject.promotions.first).to eq promotion
      end
    end

    context 'when there are no associated promotions' do
      before do
        subject.promotion_ids = []
      end
      it 'returns an empry array' do
        expect(subject.promotions).to be_empty
      end
    end
  end
end 
