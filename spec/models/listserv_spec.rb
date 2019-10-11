# frozen_string_literal: true

# == Schema Information
#
# Table name: listservs
#
#  id                          :bigint(8)        not null, primary key
#  name                        :string(255)
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
#  template                    :string
#  sponsored_by                :string
#  display_subscribe           :boolean          default(FALSE)
#  digest_subject              :string
#  digest_preheader            :string
#  sender_name                 :string
#  promotion_ids               :integer          default([]), is an Array
#  admin_email                 :string
#  forwarding_email            :string
#  forward_for_processing      :boolean          default(FALSE)
#  post_threshold              :integer          default(0)
#

require 'spec_helper'

describe Listserv, type: :model do
  it { is_expected.to respond_to(:subscribe_email, :subscribe_email=) }
  it { is_expected.to respond_to(:unsubscribe_email, :unsubscribe_email=) }
  it { is_expected.to respond_to(:post_email, :post_email=) }
  it { is_expected.to respond_to(:is_managed_list?) }
  it { is_expected.to respond_to(:promotions_list, :promotions_list=) }

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
  it { is_expected.to have_db_column(:sponsored_by).of_type(:string) }
  it { is_expected.to have_db_column(:display_subscribe).of_type(:boolean) }
  it { is_expected.to have_db_column(:digest_subject).of_type(:string) }
  it { is_expected.to have_db_column(:digest_preheader).of_type(:string) }
  it { is_expected.to have_many(:campaigns) }
  it { is_expected.to have_db_column(:admin_email).of_type(:string) }
  it { is_expected.to have_db_column(:forwarding_email).of_type(:string) }
  it { is_expected.to have_db_column(:forward_for_processing).of_type(:boolean) }
  it { is_expected.to have_db_column(:post_threshold).of_type(:integer) }

  describe '#active_subscriber_count' do
    it 'is equal to related active subscriptions' do
      ls = FactoryGirl.create :listserv
      subs = FactoryGirl.create_list :subscription, 3,
                                     listserv: ls,
                                     confirmed_at: Time.zone.now,
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

    context 'forward_for_processing is true' do
      let(:listserv) { FactoryGirl.build :listserv, forward_for_processing: true }
      it 'requires a forwarding email' do
        expect(listserv.valid?).to be false
        expect(listserv.errors).to include(:forwarding_email)
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
      let!(:promo_with_banner) do
        FactoryGirl.create :promotion,
                           promotable: FactoryGirl.create(:promotion_banner)
      end

      it 'checks existence of promotions' do
        subject.promotion_ids = %w[8675309 234234]
        subject.valid? # trigger validation
        expect(subject.errors.messages.first).to include(:promotion_ids)

        subject.promotion_ids = [promo_with_banner.id]
        subject.valid? # trigger validation
        expect(subject.errors).to_not have_key(:promotion_id)
      end

    end
  end

  describe 'mc_group_name=' do
    it 'to match mailchimp, it strips leading and trailing whitespace' do
      subject.mc_group_name = ' test '
      expect(subject.mc_group_name).to eql 'test'
    end
  end

  describe 'banner_ads' do
    let!(:promotion) { FactoryGirl.create :promotion, promotable_type: 'PromotionBanner' }
    let!(:promotion_banner) { FactoryGirl.create :promotion_banner, promotion: promotion }
    let(:banner_ad_listserv) { FactoryGirl.create :listserv, promotion_ids: [promotion.id] }

    it 'retuns an array of banner ads' do
      expect(banner_ad_listserv.banner_ads.first).to eq promotion_banner
    end
  end

  describe '#next_digest_send_time' do
    context 'daily_digest_send_time in future' do
      before do
        subject.digest_send_time = '06:00'
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
        subject.digest_send_time = '06:00'
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
      let(:listserv_with_day) do
        FactoryGirl.create :listserv,
                           digest_send_time: '06:00',
                           digest_send_day: 2.days.from_now.strftime('%A'),
                           send_digest: true,
                           digest_reply_to: 'test@example.com'
      end

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
          test_time = (Time.zone.parse('06:00') + 6.days)
          expect(send_time).to eq test_time
        end
      end
    end
  end

  describe '#digest_contents(location_ids)' do
    let!(:listserv) { FactoryGirl.create :listserv }
    let(:org) { FactoryGirl.create :organization }
    let(:location) { FactoryGirl.create :location }

    subject { listserv.digest_contents([location.id]) }

    it 'should only return max three records per organization' do
      FactoryGirl.create_list :content, 5, :news, organization: org, pubdate: 1.hour.ago, location: location
      expect(subject.length).to be 3
    end

    it 'should return max 10 records' do
      FactoryGirl.create_list :content, 15, :news, pubdate: 1.hour.ago, location: location
      expect(subject.length).to be 10
    end

    it 'should return records ordered by view_count' do
      popular_contents = FactoryGirl.create_list :content, 10, :news, pubdate: 2.hours.ago, view_count: 100, location: location
      other_contents = FactoryGirl.create_list :content, 5, :news, pubdate: 1.hour.ago, location: location
      expect(subject).to match_array(popular_contents)
    end

    it 'should only include content from the location queried' do
      other_location_content = FactoryGirl.create :content, :news, pubdate: 1.hour.ago, location: FactoryGirl.create(:location)
      expect(subject).to_not include(other_location_content)
    end

    it 'should not include removed content' do
      removed_content = FactoryGirl.create :content, :news, organization: org, pubdate: 1.hour.ago, location: location, removed: true
     expect(subject).to eq []
    end

    it 'should only include `news` content' do
      news_content = FactoryGirl.create :content, :news, pubdate: 1.hour.ago, location: location
      not_news_content = FactoryGirl.create :content, :talk, pubdate: 1.hour.ago, location: location

      expect(subject).to match_array [news_content]
    end

    context 'for a weekly digest' do
      let!(:listserv) { FactoryGirl.create :listserv, digest_send_day: Date.today.strftime('%A') }

      it 'should include contents from the last week' do
        older_content = FactoryGirl.create_list :content, 5, :news, pubdate: 5.days.ago, location: location
        expect(subject).to match_array(older_content)
      end
    end

    context 'for a daily digest' do
      let!(:listserv) { FactoryGirl.create :listserv, digest_send_day: nil }

      it 'should not include contents from older than 30 hours ago' do
        FactoryGirl.create :content, :news, pubdate: 1.hour.ago, location: location
        older_content = FactoryGirl.create :content, :news, pubdate: 3.days.ago, location: location
        expect(subject).to_not include(older_content)
      end
    end
  end

  describe 'syncing mc_group_name' do
    context 'when group name is added' do
      let(:listserv) { FactoryGirl.create :listserv }
      before do
        listserv.mc_list_id = '123'
        listserv.mc_group_name = 'Test Digest'
      end

      it 'triggers MailchimpService.find_or_create_digest' do
        expect(BackgroundJob).to receive(:perform_later).with('MailchimpService', 'add_unsubscribe_hook', listserv.mc_list_id)
        expect(BackgroundJob).to receive(:perform_later).with('MailchimpService', 'find_or_create_digest', listserv.mc_list_id, listserv.mc_group_name)
        listserv.save!
      end
    end

    context 'when group name is changed' do
      let(:listserv) do
        FactoryGirl.create :listserv,
                           mc_list_id: 321,
                           mc_group_name: 'old name'
      end
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

  describe '#promotions_list=' do
    let(:listserv) { FactoryGirl.create :listserv }
    let(:promotions) { '1,2, 5' }

    subject { listserv.promotions_list = promotions }

    it 'should split the string and assign values to promotion_ids' do
      expect { subject }.to change { listserv.promotion_ids }.to [1, 2, 5]
    end
  end

  describe '#promotions_list' do
    let(:listserv) { FactoryGirl.create :listserv }
    before { listserv.promotion_ids = [1, 2, 5] }

    subject { listserv.promotions_list }

    it 'should combine promotion_ids into a string with comma space separator' do
      expect(subject).to eq '1, 2, 5'
    end
  end

  describe 'template name validation' do
    let(:listserv) { FactoryGirl.create :listserv }

    describe 'for a valid template' do
      before do
        listserv.template = 'fake template'
        stub_const('Listserv::DIGEST_TEMPLATES', ['fake template'])
      end

      it 'should be valid' do
        expect(listserv).to be_valid
      end
    end

    describe 'for nil template' do
      it 'should be valid' do
        expect(listserv).to be_valid
      end
    end

    describe 'for an invalid template' do
      before do
        listserv.template = 'fake template'
        stub_const('Listserv::DIGEST_TEMPLATES', ['other fake'])
      end

      it 'should not be valid' do
        expect(listserv).to_not be_valid
      end
    end
  end

  describe '#locations' do
    let(:listserv) { FactoryGirl.create :listserv }
    let(:location) { FactoryGirl.create :location }

    subject { listserv.locations }

    context 'with no subscriptions' do
      it 'should return nothing' do
        expect(subject.length).to be 0
      end
    end

    context 'with multiple subscriptions in the same location' do
      let!(:subscriptions) do
        FactoryGirl.create_list :subscription, 3, :subscribed, listserv: listserv,
          user: FactoryGirl.create(:user, location: location)
      end

      it 'should return that location' do
        expect(subject).to match_array [location]
      end
    end

    context 'with multiple different location subscriptions' do
      let(:loc2) { FactoryGirl.create :location }
      let!(:sub1) { FactoryGirl.create :subscription, :subscribed, listserv: listserv,
                    user: FactoryGirl.create(:user, location: location) }
      let!(:sub2) { FactoryGirl.create :subscription, :subscribed, listserv: listserv,
                    user: FactoryGirl.create(:user, location: loc2) }

      it 'should return all locations' do
        expect(subject).to match_array [location, loc2]
      end
    end
  end
end
