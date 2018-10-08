require 'rails_helper'

RSpec.describe PromoteContentToListservs do
  let(:user) { FactoryGirl.create :user }
  let(:remote_ip) { '1.1.1.1' }
  let(:listservs) { FactoryGirl.create_list :listserv, 3 }
  let(:content) { FactoryGirl.create :content, created_by: user }

  before do
    listservs.each do |ls|
      ls.update locations: [ FactoryGirl.create(:location) ]
    end
    
    allow(BitlyService).to receive(:create_short_link).with(any_args).and_return('http://bit.ly/12345')
  end

  context 'Given content, remote_ip, and *listservs, ' do
    subject { described_class.call(content, remote_ip, *listservs) }

    it 'creates a PromotionListserv for each listserv record' do
      expect{subject}.to change{
        PromotionListserv.count
      }.by(3)

      PromotionListserv.last(3).sort_by(&:id).each_with_index do |pl, index|
        expect(pl.promotion.content).to eql content
        expect(pl.listserv).to eql listservs[index]
      end
    end

    it 'adds the locations of the listservs to the content record' do
      locations = listservs.collect(&:locations).flatten
      subject
      expect(content.reload.locations).to include(*locations)
    end

    it 'creates a bitly link and saves it to the content record' do
      subject
      expect(content.reload.short_link).to eq('http://bit.ly/12345')
    end

    context "When some are external" do
      before do
        subset = listservs.sort_by(&:id).first(2)
        subset.each_with_index do |ls,i|
          ls.update! reverse_publish_email: "test#{i}@test.com"
        end
      end


      it 'should update sent_at with the current time', freeze_time: true do
        tm = Time.zone.now
        test_group = PromotionListserv.order("id asc").first(2)
        test_group.each do |pl|
          expect(pl.sent_at).to be_within(1.second).of tm
        end
      end

    end

    context 'Several are external listservs;' do
      before do
        6.times do
          listservs << FactoryGirl.create(:vc_listserv)
        end
      end

      it 'should send two emails (list, confirmation) for the vc_list', inline_jobs: true do
        expect{subject}.to change{ActionMailer::Base.deliveries.count}.by 2

        first = ActionMailer::Base.deliveries.first
        second = ActionMailer::Base.deliveries.second

        reverse_publish_emails = listservs.select(&:is_vc_list?).map(&:reverse_publish_email)
        expect(first.to).to include(*reverse_publish_emails)
        expect(second.to).to include(content.authoremail)
      end
    end
  end
end
