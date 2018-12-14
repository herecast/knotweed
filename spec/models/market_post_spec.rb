# == Schema Information
#
# Table name: market_posts
#
#  id                       :bigint(8)        not null, primary key
#  cost                     :string(255)
#  contact_phone            :string(255)
#  contact_email            :string(255)
#  contact_url              :string(255)
#  locate_name              :string(255)
#  locate_address           :string(255)
#  latitude                 :float
#  longitude                :float
#  locate_include_name      :boolean
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  status                   :string(255)
#  preferred_contact_method :string(255)
#  sold                     :boolean          default(FALSE)
#

require 'spec_helper'

describe MarketPost, :type => :model do
  before do
    @content = FactoryGirl.create :content
    @market_post = FactoryGirl.create :market_post, content: @content
  end

  describe "method missing override" do
    it "should allow access to content attributes directly" do
      expect(@market_post.title).to eq(@content.title)
      expect(@market_post.authors).to eq(@content.authors)
      expect(@market_post.pubdate).to eq(@content.pubdate)
    end

    it "should retain normal method_missing behavior if not a content attribute" do
      expect { @market_post.asdfdas }.to raise_error(NoMethodError)
    end
  end

  describe "after_save" do
    it "should also save the associated content record" do
      @content.title = "Changed Title"
      @market_post.save # should trigger @content.save callback
      expect(@content.reload.title).to eq "Changed Title"
    end
  end

  describe "contact phone validation" do
    it "does not accept alpha characters for contact phone" do
      @market_post.contact_phone = "SSS-0123"
      @market_post.valid?
      expect(@market_post.errors).to_not be_nil
      expect(@market_post.errors.full_messages).to include "Contact phone is invalid"
    end

    it "allows for 'x' or 'X' for phone extensions" do
      @market_post.contact_phone = "555-2368 X123"
      @market_post.valid?
      expect(@market_post.errors.any?).to be false
      @market_post.contact_phone = "555-2368 x123"
      @market_post.valid?
      expect(@market_post.errors.any?).to be false
    end
  end
end
