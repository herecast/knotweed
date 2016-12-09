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
#  digest_send_time            :time
#  unsubscribe_email           :string
#  post_email                  :string
#  subscribe_email             :string
#  mc_list_id                  :string
#  mc_group_name               :string
#  send_digest                 :boolean          default(FALSE)
#  last_digest_send_time       :datetime
#  last_digest_generation_time :datetime
#  digest_header               :text
#  digest_footer               :text
#  digest_reply_to             :string
#  timezone                    :string           default("Eastern Time (US & Canada)")
#  digest_description          :text
#  digest_send_day             :string
#  promotion_id                :integer
#  digest_query                :text
#  template                    :string
#  sponsored_by                :string
#  display_subscribe           :boolean          default(FALSE)
#  digest_subject              :string
#  digest_preheader            :string
#  list_type                   :string           default("custom_list")
#  sender_name                 :string
#

require 'spec_helper'

describe Listserv, :type => :model do

  it { is_expected.to respond_to(:subscribe_email, :subscribe_email=) }
  it { is_expected.to respond_to(:unsubscribe_email, :unsubscribe_email=) }
  it { is_expected.to respond_to(:post_email, :post_email=) }
  it { is_expected.to respond_to(:is_managed_list?) }
  it { is_expected.to respond_to(:is_vc_list?) }

  it { is_expected.to have_db_column(:mc_list_id).of_type(:string) }
  it { is_expected.to have_db_column(:mc_group_name).of_type(:string) }
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
  it { is_expected.to have_db_column(:sponsored_by).of_type(:string) }
  it { is_expected.to have_db_column(:display_subscribe).of_type(:boolean) }
  it { is_expected.to have_db_column(:digest_subject).of_type(:string) }
  it { is_expected.to have_db_column(:digest_preheader).of_type(:string) }
  it { is_expected.to have_many(:campaigns) }
  it { is_expected.to have_db_column(:list_type).of_type(:string) }

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

  describe '#mc_sync?' do
    it 'is true when mc_list_id? and mc_group_name?' do
      expect(subject.mc_sync?).to eql (subject.mc_list_id? && subject.mc_group_name?)
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

    context 'when mc_list_id' do
      before do
        subject.mc_list_id = '123432kl;'
      end

      it 'requires mc_group_name' do
        expect(subject).to be_invalid
        expect(subject.errors[:mc_group_name]).to include('required when mc_list_id present')
      end
    end

    context 'when given a promotion id' do
      let!(:promo_with_banner) {
        FactoryGirl.create :promotion,
          promotable: FactoryGirl.create(:promotion_banner)
      }

      let!(:other_promo) {
        FactoryGirl.create :promotion,
          promotable: FactoryGirl.create(:promotion_listserv)
      }

      it 'checks existence of the promotion' do
        subject.promotion_id = '190380'
        subject.valid? #trigger validation
        expect(subject.errors).to have_key(:promotion_id)

        subject.promotion_id = promo_with_banner.id
        subject.valid? #trigger validation
        expect(subject.errors).to_not have_key(:promotion_id)
      end

      it 'requires promotion is tied to a PromotionBanner' do
        subject.promotion_id = other_promo.id
        subject.valid? #trigger validation
        expect(subject.errors).to have_key(:promotion_id)

        subject.promotion_id = promo_with_banner.id
        subject.valid? #trigger validation
        expect(subject.errors).to_not have_key(:promotion_id)
      end
    end

  end

  describe 'mc_group_name=' do
    it 'to match mailchimp, it strips leading and trailing whitespace' do
      subject.mc_group_name= " test "
      expect(subject.mc_group_name).to eql "test"
    end
  end

  describe 'banner_ad' do
    let!(:promotion) { FactoryGirl.create :promotion, promotable_type: 'PromotionBanner' }
    let!(:promotion_banner) { FactoryGirl.create :promotion_banner, promotion: promotion }
    let(:banner_ad_listserv) { FactoryGirl.create :listserv, promotion: promotion }
  
   it 'retuns a banner ad' do
      expect(banner_ad_listserv.banner_ad).to eq promotion_banner
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
         send_time = listserv_with_day.next_digest_send_time
         test_time = Time.zone.parse('06:00') + 2.days
         expect(send_time).to eq test_time
        end
      end

      it 'returns the correct send time if day is next week' do
        listserv_with_day.update_attributes(digest_send_day: 1.day.ago.strftime('%A'))
        Timecop.freeze(Time.zone.now) do
          send_time = listserv_with_day.next_digest_send_time
          test_time = Time.zone.parse('06:00') + 6.days
          expect(send_time).to eq test_time
        end
      end
    end
  end

  describe '#contents_from_custom_query' do
    context 'when custom query exists, with matching records' do
      let!(:contents) { FactoryGirl.create_list :content, 3 }
      let!(:listserv) { Listserv.new }
      before do
        listserv.digest_query = "SELECT * FROM contents"
      end

      subject { listserv.contents_from_custom_query }

      it "is equal to matching records" do
        expect(subject).to match_array contents
      end

      it 'maintains the same sort order' do
        listserv.digest_query += " ORDER BY id DESC"
        expect(subject.first).to eql contents.sort_by(&:id).reverse.first
      end
    end
  end

  describe 'syncing mc_group_name' do
    context 'when group name is added' do
      let(:listserv) { FactoryGirl.create :listserv }
      before do
        listserv.mc_list_id="123"
        listserv.mc_group_name = 'Test Digest'
      end

      it 'triggers MailchimpService.find_or_create_digest' do
        expect(BackgroundJob).to receive(:perform_later).with('MailchimpService', 'add_unsubscribe_hook', listserv.mc_list_id)
        expect(BackgroundJob).to receive(:perform_later).with('MailchimpService', 'find_or_create_digest', listserv.mc_list_id, listserv.mc_group_name)
        listserv.save!
      end
    end

    context 'when group name is changed' do
      let(:listserv) {
        FactoryGirl.create :listserv,
          mc_list_id: 321,
          mc_group_name: 'old name'
      }
      before do
        listserv.mc_group_name = 'Test Digest'
      end

      it 'triggers MailchimpService.find_or_create_digest' do
        expect(BackgroundJob).to receive(:perform_later).with('MailchimpService', 'rename_digest', listserv.mc_list_id, 'old name', 'Test Digest')
        listserv.save!
      end
    end
  end

  describe 'adding mailchimp webhook' do
    let(:listserv) { FactoryGirl.build_stubbed :listserv, mc_list_id: '123', mc_group_name: 'group_name' }
    let!(:persisted_listserv) { FactoryGirl.create :listserv, mc_list_id: '000', mc_group_name: 'group_name' }

    before do
      allow(BackgroundJob).to receive(:perform_later).with('MailchimpService', 'find_or_create_digest', listserv.mc_list_id, listserv.mc_group_name).and_return(true)
    end

    it 'triggers Mailchimp.add_mc_webhook when saving a listserv' do
      expect(BackgroundJob).to receive(:perform_later).with('MailchimpService', 'add_unsubscribe_hook', listserv.mc_list_id)
      listserv.save!
    end

    it 'triggers MailchimpService when a listserv mc_list_id changes' do
      expect(BackgroundJob).to receive(:perform_later).with('MailchimpService', 'add_unsubscribe_hook', '321')
      persisted_listserv.update_attributes(mc_list_id: '321')
      persisted_listserv.save!
    end
  end

end
