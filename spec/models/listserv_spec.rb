# == Schema Information
#
# Table name: listservs
#
#  id                          :integer          not null, primary key
#  name                        :string(255)
#  reverse_publish_email       :string(255)
#  import_name                 :string(255)
#  active                      :boolean
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  daily_digest_send_time      :time
#  unsubscribe_email           :string(255)
#  post_email                  :string(255)
#  subscribe_email             :string(255)
#  send_digest                 :boolean          default(FALSE)
#  last_digest_send_time       :datetime
#  last_digest_generation_time :datetime
#  mc_list_id                  :string(255)
#  mc_segment_id               :string(255)
#

require 'spec_helper'

describe Listserv, :type => :model do

  it { is_expected.to respond_to(:subscribe_email, :subscribe_email=) }
  it { is_expected.to respond_to(:unsubscribe_email, :unsubscribe_email=) }
  it { is_expected.to respond_to(:post_email, :post_email=) }
  it { is_expected.to respond_to(:is_managed_list?) }
  it { is_expected.to respond_to(:is_vc_list?) }

  it { is_expected.to have_db_column(:mc_list_id).of_type(:string) }
  it { is_expected.to have_db_column(:mc_segment_id).of_type(:string) }
  it { is_expected.to have_db_column(:send_digest).of_type(:boolean) }
  it { is_expected.to have_db_column(:last_digest_send_time).of_type(:datetime) }
  it { is_expected.to have_db_column(:last_digest_generation_time).of_type(:datetime) }
  it { is_expected.to have_db_column(:digest_header).of_type(:text) }
  it { is_expected.to have_db_column(:digest_footer).of_type(:text) }
  it { is_expected.to have_db_column(:digest_reply_to).of_type(:string) }
  it { is_expected.to have_db_column(:timezone).of_type(:string) }
  it { is_expected.to have_db_column(:digest_description).of_type(:text) }
  it { is_expected.to have_db_column(:digest_send_day).of_type(:string) }
  it { is_expected.to have_db_column(:digest_query).of_type(:text) }
  describe '#active_subscriber_count' do
    it 'is equal to related active subscriptions' do
      ls = FactoryGirl.create :listserv
      subs = FactoryGirl.create_list :subscription, 3,
        listserv: ls,
        confirmed_at: Time.now,
        confirm_ip: '1.1.1.1'

      expect(ls.active_subscriber_count).to eql subs.count
    end
  end

  describe 'validation' do
    describe 'should prevent a user from populating managed list fields if `reverse_publish_email` is populated' do
      let(:listserv) { FactoryGirl.create :vc_listserv }

      subject { listserv.post_email = Faker::Internet.email && listserv }

      it { expect(subject).to_not be_valid }
    end

    describe 'should prevent a user from populating `reverse_publish_email` if managed list fields are populated' do
      let(:listserv) { FactoryGirl.create :subtext_listserv }

      subject { listserv.reverse_publish_email = Faker::Internet.email && listserv }

      it { expect(subject).to_not be_valid }
    end

    describe 'should prevent user from using queries to alter data' do
      let(:listserv) { FactoryGirl.build :listserv, digest_query: "DROP DB"}
      it 'does not save digest query with data altering commands' do
        expect(listserv.valid?).to be false
        expect(listserv.errors[:digest_query]).to include "Commands to alter data are not allowed"
      end
    end

    context 'send_digest is true' do
      let(:listserv) { FactoryGirl.build :listserv, send_digest: true }

      it 'requires digest_reply_to' do
        listserv.digest_reply_to = nil
        expect(listserv).to_not be_valid
        expect(listserv.errors).to include(:digest_reply_to)
      end

      it 'requires digest_send_time' do
        listserv.digest_send_time = nil
        expect(listserv).to_not be_valid
        expect(listserv.errors).to include(:digest_send_time)
      end
    end
  end

  describe 'banner_ad' do
    let!(:banner_ad) { FactoryGirl.create :promotion_banner }
    let(:banner_ad_listserv) { FactoryGirl.create :listserv, banner_ad_override_id: banner_ad.id }
    it 'retuns a banner ad' do
      expect(banner_ad_listserv.banner_ad).to eq banner_ad
    end
  end

  describe '#next_digest_send_time' do
    context 'daily_digest_send_time in future' do
      before do
        subject.digest_send_time = "06:00"
      end

      it 'returns today send time' do
        Timecop.freeze(Time.zone.parse('02:00')) do
          tm = subject.next_digest_send_time
          expect(tm).to be_today
          expect(tm.strftime('%H:%M')).to eql '06:00'
        end
      end
    end

    context 'daily_digest_send_time in past' do
      before do
        subject.digest_send_time = "06:00"
      end

      it 'returns tomorrow send time' do
        Timecop.freeze(Time.zone.parse('08:00')) do
          tm = subject.next_digest_send_time
          expect(tm).to be_future
          expect(tm).to be > Time.current.end_of_day
          expect(tm.strftime('%H:%M')).to eql '06:00'
        end
      end
    end

    context 'when digest send day is present' do
      let(:listserv_with_day) { FactoryGirl.create :listserv, 
                                digest_send_time: "06:00",
                                digest_send_day: 2.days.from_now.strftime('%A'),
                                send_digest: true, 
                                digest_reply_to: "test@example.com" }

      it 'returns the correct send time if day is upcoming in the week' do
        Timecop.freeze(Time.zone.now) do
         tm = listserv_with_day.next_digest_send_time
         expect(tm.strftime("%B %D")).to eq 2.days.from_now.strftime("%B %D")
        end
      end

      it 'returns the correct send time if day is next week' do
        listserv_with_day.update_attributes(digest_send_day: 1.day.ago.strftime('%A'))
        Timecop.freeze(Time.zone.now) do
          tm = listserv_with_day.next_digest_send_time
          expect(tm.strftime("%B %D")).to eq 6.days.from_now.strftime("%B %D")
        end
      end
    end
  end

end
