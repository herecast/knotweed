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

require 'spec_helper'

describe PromotionListserv, :type => :model do
  before { ActiveJob::Base.queue_adapter = :test }

  describe 'create_from_content' do

    it 'should create a Promotion / PromotionListserv object pair' do
      list = FactoryGirl.create :listserv
      content = FactoryGirl.create :content
      pl = PromotionListserv.create_from_content(content, list)
      expect(pl.is_a?(PromotionListserv)).to be_truthy
      expect(pl.promotion.is_a?(Promotion)).to be_truthy
      expect(pl.promotion.content).to eq(content)
    end

    it 'should fail if the listserv is inactive' do
      list = FactoryGirl.create :listserv, active: false
      content = FactoryGirl.create :content
      pl = PromotionListserv.create_from_content(content, list)
      expect(pl).to be_falsey
    end

    it 'should fail if there is no authoremail present' do
      list = FactoryGirl.create :listserv
      content = FactoryGirl.create :content, authoremail: nil
      pl = PromotionListserv.create_from_content(content, list)
      expect(pl).to be_falsey
      content = FactoryGirl.create :content
    end
      
  end

  describe 'after_create send_content_to_listserv' do
    before do
      @listserv = FactoryGirl.create :listserv
      @loc1 = FactoryGirl.create :location
      @loc2 = FactoryGirl.create :location
      @listserv.locations << @loc1
      @content = FactoryGirl.create :content
      @pl = PromotionListserv.create_from_content(@content, @listserv)
    end

    it 'should update sent_at with the current time' do
      @pl.reload
      expect(@pl.sent_at.present?).to be_truthy
    end

    it 'should update the locations of the content record' do
      expect(@content.locations.include?(@loc1)).to be_truthy
    end

  end
  
end
