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
  it{ is_expected.to belong_to :listserv_content }

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

    end
  end
end
