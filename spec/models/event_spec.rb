# == Schema Information
#
# Table name: events
#
#  id             :integer          not null, primary key
#  event_type     :string(255)
#  venue_id       :integer
#  cost           :string(255)
#  event_url      :string(255)
#  sponsor        :string(255)
#  sponsor_url    :string(255)
#  links          :text
#  featured       :boolean
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  contact_phone  :string(255)
#  contact_email  :string(255)
#  cost_type      :string(255)
#  event_category :string(255)
#  social_enabled :boolean          default(FALSE)
#

require 'spec_helper'

describe Event do
  before do
    @content = FactoryGirl.create :content
    @event = FactoryGirl.create :event, content: @content
  end

  describe "method missing override" do
    it "should allow access to content attributes directly" do
      @event.title.should eq(@content.title)
      @event.authors.should eq(@content.authors)
      @event.pubdate.should eq(@content.pubdate)
    end

    it "should retain normal method_missing behavior if not a content attribute" do
      expect { @event.asdfdas }.to raise_error(NoMethodError)
    end
  end

  describe "description" do
    it "should return content.content" do
      @event.description.should eq(@content.content)
    end
  end

  describe "description=" do
    it "should update the associated content record's content field" do
      @event.description = "New Description"
      @event.content.content.should eq "New Description"
    end
  end

  describe "after_save" do
    it "should also save the associated content record" do
      @content.title = "Changed Title"
      @event.save # should trigger @content.save callback
      @content.reload.title.should eq "Changed Title"
    end
  end

  describe 'before_save' do
    it 'should ensure that all URL fields start with http://' do
      @event.sponsor_url = @event.event_url = 'www.google.com'
      @event.save
      @event.reload
      @event.sponsor_url.should eq('http://www.google.com')
      @event.event_url.should eq('http://www.google.com')
    end

    it 'should not affect URL fields that already have http' do
      @event.sponsor_url = 'http://www.google.com'
      @event.save
      @event.reload
      @event.sponsor_url.should eq('http://www.google.com')
    end
  end

end
