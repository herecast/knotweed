# == Schema Information
#
# Table name: market_posts
#
#  id                       :integer          not null, primary key
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
#

require 'spec_helper'

describe MarketPost do
  before do
    @content = FactoryGirl.create :content
    @market_post = FactoryGirl.create :market_post, content: @content
  end

  describe "method missing override" do
    it "should allow access to content attributes directly" do
      @market_post.title.should eq(@content.title)
      @market_post.authors.should eq(@content.authors)
      @market_post.pubdate.should eq(@content.pubdate)
    end

    it "should retain normal method_missing behavior if not a content attribute" do
      expect { @market_post.asdfdas }.to raise_error(NoMethodError)
    end
  end

  describe "after_save" do
    it "should also save the associated content record" do
      @content.title = "Changed Title"
      @market_post.save # should trigger @content.save callback
      @content.reload.title.should eq "Changed Title"
    end
  end

end
