# == Schema Information
#
# Table name: promotion_listservs
#
#  id          :integer          not null, primary key
#  listserv_id :integer
#  sent_at     :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'rails_helper'

describe PromotionListserv, :type => :model do
  let(:content) { FactoryGirl.create :content }

  context 'for vc_listservs' do
    let(:list) { FactoryGirl.create :vc_listserv }

    describe 'create_from_content' do
      subject { PromotionListserv.create_from_content(content, list) }

      it 'should create a Promotion / PromotionListserv object pair' do
        expect(subject.is_a?(PromotionListserv)).to be_truthy
        expect(subject).to be_persisted
        expect(subject.promotion.is_a?(Promotion)).to be_truthy
        expect(subject.promotion.promotable_type).to eql 'PromotionListserv'
        expect(subject.promotion).to be_persisted
        expect(subject.promotion.content).to eq(content)
      end

      it 'should fail if the listserv is inactive' do
        list.active = false
        expect(subject).to be_falsey
      end

      it 'should fail if there is no authoremail present' do
        content.authoremail = nil
        expect(subject).to be_falsey
      end

      it 'should update sent_at with the current time' do
        expect(subject.sent_at.present?).to be_truthy
      end

      describe 'with listserv location' do
        it 'should update the locations of the content record' do
          loc = FactoryGirl.create :location
          list.locations << loc
          subject
          expect(content.locations.include?(loc)).to be_truthy
        end
      end
    end
  end

  context 'for a Subtext list' do
    describe 'create_from_content' do
      let(:list) { FactoryGirl.create :subtext_listserv }

      subject { PromotionListserv.create_from_content(content, list) }

      it 'should not update sent_at' do
        # because it doesn't actually do the sending for subtext lists
        expect(subject.sent_at.present?).to be_falsey
      end

      it 'should update the locations of the content record' do
        loc = FactoryGirl.create :location
        list.locations << loc
        subject
        expect(content.locations.include?(loc)).to be_truthy
      end
    end
  end

  describe 'create_multiple_from_content', inline_jobs: true do
    context 'with both vc lists and subtext lists' do
      let(:vc_list) { FactoryGirl.create :vc_listserv }
      let(:subtext_list) { FactoryGirl.create :subtext_listserv }

      subject { PromotionListserv.create_multiple_from_content(content, [vc_list.id, subtext_list.id]) }

      describe 'locations' do
        it 'should assign locations from both lists to the content' do
          vc_list.locations << (loc1 = FactoryGirl.create :location)
          subtext_list.locations << (loc2 = FactoryGirl.create :location)
          subject
          expect(content.locations).to match_array [loc1,loc2]
        end
      end

      it 'should create PromotionListservs for each list' do
        expect{subject}.to change{PromotionListserv.count}.by 2
      end

      it 'should link PromotionListservs to Promotions' do
        expect(subject.count).to eql 2
        subject.each do |p|
          expect(p.reload.promotable).to be_a PromotionListserv
        end
      end

      it 'should send two emails (list, confirmation) for the vc_list' do
        expect{subject}.to change{ActionMailer::Base.deliveries.count}.by 2
      end
    end
  end

end
