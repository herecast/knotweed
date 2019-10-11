# frozen_string_literal: true

require 'spec_helper'
require 'cancan/matchers'

describe Ability, type: :model do
  before do
    # ensure that -- regardless of spec order --
    # users are not "logged in" during this execution
    User.current = nil
  end

  describe 'abilities' do
    subject(:ability) { Ability.new(user) }
    let(:user) { nil }

    context 'when not logged in' do
      it { is_expected.not_to be_able_to(:manage, :all) }
      it { is_expected.not_to be_able_to(:access, :rails_admin) }
      it { is_expected.not_to be_able_to(:access, :admin) }
    end

    context 'when is an admin user' do
      let(:user) { FactoryGirl.create(:admin) }

      it { is_expected.to be_able_to(:manage, :all) }
      it { is_expected.to be_able_to(:access, :rails_admin) }
      it { is_expected.to be_able_to(:access, :admin) }
    end

    context 'when is an organization manager' do
      before do
        @user = FactoryGirl.create :user
        @org = FactoryGirl.create :organization
        @child = FactoryGirl.create :organization, parent: @org
        @org_content = FactoryGirl.create :content, organization_id: @org.id
        @child_content = FactoryGirl.create :content, organization_id: @child.id

        @user.add_role :manager, @org
      end

      let(:hashie_content_by_org) do
        Hashie::Mash.new(_type: 'content', organization_id: @org.id)
      end

      let(:hashie_content_by_child_org) do
        Hashie::Mash.new(_type: 'content', organization_id: @child.id)
      end

      let(:hashie_event_instance_by_org) do
        Hashie::Mash.new(_type: 'event_instance', organization_id: @org.id)
      end

      let(:hashie_event_instance_by_child_org) do
        Hashie::Mash.new(_type: 'event_instance', organization_id: @child.id)
      end

      let(:user) { @user }

      it { is_expected.to be_able_to(:access, :admin) }
      it { is_expected.to be_able_to(:manage, @org) }
      it { is_expected.to be_able_to(:manage, @child) }
      it { is_expected.to be_able_to(:manage, @org_content) }
      it { is_expected.to be_able_to(:manage, @child_content) }

      it { is_expected.to be_able_to(:manage, hashie_content_by_org) }
      it { is_expected.to be_able_to(:manage, hashie_content_by_child_org) }
      it { is_expected.to be_able_to(:manage, hashie_event_instance_by_org) }
      it { is_expected.to be_able_to(:manage, hashie_event_instance_by_child_org) }
    end

    context 'when is an event manager' do
      before do
        @user           = FactoryGirl.create :user
        @event          = FactoryGirl.create :event

        @user.add_role :event_manager
      end

      let(:user) { @user }

      let(:hashie_content_event) do
        Hashie::Mash.new(_type: 'content', content_category: 'event')
      end

      it { is_expected.to be_able_to(:access, :dashboard) }
      it { is_expected.to be_able_to(:manage, @event.content) }
      it { is_expected.to be_able_to(:manage, @event.venue) }

      it { is_expected.to be_able_to(:manage, hashie_content_event) }
    end

    context 'when is a regular user' do
      before do
        @user = FactoryGirl.create :user
        @content = FactoryGirl.create :content, created_by: @user
        @other_content = FactoryGirl.create :content, created_by: nil
      end

      let(:user) { @user }

      let(:hashie_content_owned) do
        Hashie::Mash.new(_type: 'content', created_by: { id: user.id })
      end

      let(:hashie_content_not_owned) do
        Hashie::Mash.new(_type: 'content', created_by: { id: 9_099_809 })
      end

      let(:hashie_instance_owned) do
        Hashie::Mash.new(_type: 'event_instance', created_by: { id: user.id })
      end

      let(:hashie_instance_not_owned) do
        Hashie::Mash.new(_type: 'event_instance', created_by: { id: 9_099_809 })
      end

      it { is_expected.to be_able_to(:manage, @content) }
      it { is_expected.not_to be_able_to(:manage, @other_content) }

      it { is_expected.to be_able_to(:manage, hashie_content_owned) }
      it { is_expected.not_to be_able_to(:manage, hashie_content_not_owned) }
      it { is_expected.to be_able_to(:manage, hashie_instance_owned) }
      it { is_expected.not_to be_able_to(:manage, hashie_instance_not_owned) }
    end
  end
end
