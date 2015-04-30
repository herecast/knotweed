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

describe PromotionListserv do

  describe 'create_from_content' do

    it 'should create a Promotion / PromotionListserv object pair' do
      list = FactoryGirl.create :listserv
      content = FactoryGirl.create :content
      pl = PromotionListserv.create_from_content(content, list)
      pl.is_a?(PromotionListserv).should be_true
      pl.promotion.is_a?(Promotion).should be_true
      pl.promotion.content.should == content
    end

    it 'should fail if the listserv is inactive' do
      list = FactoryGirl.create :listserv, active: false
      content = FactoryGirl.create :content
      pl = PromotionListserv.create_from_content(content, list)
      pl.should be_false
    end

    it 'should fail if there is no authoremail present' do
      list = FactoryGirl.create :listserv
      content = FactoryGirl.create :content, authoremail: nil
      pl = PromotionListserv.create_from_content(content, list)
      pl.should be_false
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
      @pl.sent_at.present?.should be_true
    end

    it 'should update the locations of the content record' do
      @content.locations.include?(@loc1).should be_true
    end


  end
  
end
