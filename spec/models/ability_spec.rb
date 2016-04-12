require 'spec_helper'
require "cancan/matchers"

describe Ability, :type => :model do
  before do
    # ensure that -- regardless of spec order --
    # users are not "logged in" during this execution
    User.current = nil
  end

  describe "abilities" do
    subject(:ability) { Ability.new(user) }
    let(:user) { nil }

    context "when not logged in" do
      it { is_expected.not_to be_able_to(:manage, :all) }
      it { is_expected.not_to be_able_to(:access, :rails_admin) }
      it { is_expected.not_to be_able_to(:access, :admin) }
    end

    context "when is an admin user" do
      let(:user){ FactoryGirl.create(:admin) }

      it{ is_expected.to be_able_to(:manage, :all) }
      it{ is_expected.to be_able_to(:access, :rails_admin) }
      it{ is_expected.to be_able_to(:access, :admin) }
    end

    context "when is an organization manager" do
      before do
        @user = FactoryGirl.create :user
        @org = FactoryGirl.create :organization
        @child = FactoryGirl.create :organization, parent: @org
        @org_content = FactoryGirl.create :content, organization_id: @org.id
        @child_content = FactoryGirl.create :content, organization_id: @child.id

        @user.add_role :manager, @org
      end

      let(:user){ @user }

      it{ is_expected.to be_able_to(:access, :admin) }
      it{ is_expected.to be_able_to(:manage, @org) }
      it{ is_expected.to be_able_to(:manage, @child) }
      it{ is_expected.to be_able_to(:manage, @org_content) }
      it{ is_expected.to be_able_to(:manage, @child_content) }
    end

    context "when is an event manager" do
      before do
        @user           = FactoryGirl.create :user
        @event_category = FactoryGirl.create :content_category, name: 'event'
        @event          = FactoryGirl.create :event
        @content        = FactoryGirl.create :content
        @event.content.update_attribute(:content_category, @event_category)
        @content.update_attribute(:created_by, @user)
        
        @user.add_role :event_manager
      end

      let(:user){ @user }

      it{ is_expected.to be_able_to(:access, :dashboard) }
      it{ is_expected.to be_able_to(:manage, @event.content) }
      it{ is_expected.to be_able_to(:manage, @event.venue) }
      it{ is_expected.to be_able_to(:manage, @content) }
      
    end

    context 'when is a regular user' do
      before do
        @user = FactoryGirl.create :user
        @content = FactoryGirl.create :content, created_by: @user
        @other_content = FactoryGirl.create :content, created_by: nil
      end

      let(:user){ @user }

      it { is_expected.to be_able_to(:manage, @content) }
      it { is_expected.not_to be_able_to(:manage, @other_content) }
    end
  end
end
