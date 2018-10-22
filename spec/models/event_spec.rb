# == Schema Information
#
# Table name: events
#
#  id                    :bigint(8)        not null, primary key
#  event_type            :string(255)
#  venue_id              :bigint(8)
#  cost                  :string(255)
#  event_url             :string
#  sponsor               :string(255)
#  sponsor_url           :string(255)
#  links                 :text
#  featured              :boolean
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  contact_phone         :string(255)
#  contact_email         :string(255)
#  cost_type             :string(255)
#  event_category        :string(255)
#  social_enabled        :boolean          default(FALSE)
#  registration_deadline :datetime
#  registration_url      :string(255)
#  registration_phone    :string(255)
#  registration_email    :string(255)
#
# Indexes
#
#  idx_16615_events_on_venue_id_index  (venue_id)
#  idx_16615_index_events_on_featured  (featured)
#  idx_16615_index_events_on_venue_id  (venue_id)
#

require 'spec_helper'

describe Event, :type => :model do
  before do
    @event = FactoryGirl.create :event
    @content = @event.content
  end

  describe "method missing override" do
    it "should allow access to content attributes directly" do
      expect(@event.title).to eq(@content.title)
      expect(@event.authors).to eq(@content.authors)
      expect(@event.pubdate).to eq(@content.pubdate)
    end

    it "should retain normal method_missing behavior if not a content attribute" do
      expect { @event.asdfdas }.to raise_error(NoMethodError)
    end
  end

  describe "description" do
    it "should return content.content" do
      expect(@event.description).to eq(@content.content)
    end
  end

  describe "description=" do
    it "should update the associated content record's content field" do
      @event.description = "New Description"
      expect(@event.content.content).to eq "New Description"
    end
  end

  describe "after_save" do
    it "should also save the associated content record" do
      @content.title = "Changed Title"
      @event.save # should trigger @content.save callback
      expect(@content.reload.title).to eq "Changed Title"
    end
  end

  describe 'before_save' do
    it 'should ensure that all URL fields start with http://' do
      @event.sponsor_url = @event.event_url = 'www.google.com'
      @event.save
      @event.reload
      expect(@event.sponsor_url).to eq('http://www.google.com')
      expect(@event.event_url).to eq('http://www.google.com')
    end

    it 'should not affect URL fields that already have http' do
      @event.sponsor_url = 'http://www.google.com'
      @event.save
      @event.reload
      expect(@event.sponsor_url).to eq('http://www.google.com')
    end
  end

  describe '#owner_name' do
    context "when organization owns event" do
      before do
        @organization = FactoryGirl.create :organization, name: 'Fake Org'
        @content.update_attribute(:organization_id, @organization.id)
      end

      it "owner is organization name" do
        expect(@event.owner_name).to eq @organization.name
      end
    end

    context "when no organization owns an event but a user created it" do
      before do
        @user = FactoryGirl.create :user, name: 'Hodor'
        @content.update_attribute(:created_by, @user)
        @content.update_attribute(:organization_id, nil)
      end

      it "owner is user name" do
        expect(@event.owner_name).to eq @user.name
      end
    end

    context "when no organization owns event and created_by is nil" do
      before do
        @content.update_attribute(:organization_id, nil)
        @content.update_attribute(:created_by, nil)
      end

      it "returns nil" do
        expect(@event.owner_name).to be_nil
      end
    end
  end

end
