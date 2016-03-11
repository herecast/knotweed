require 'spec_helper'
require "cancan/matchers"

describe Ability do
  before do
    # ensure that -- regardless of spec order --
    # users are not "logged in" during this execution
    User.current = nil
  end

  describe "abilities" do
    subject(:ability) { Ability.new(user) }
    let(:user) { nil }

    context "when not logged in" do
      it { should_not be_able_to(:manage, :all) }
      it { should_not be_able_to(:access, :rails_admin) }
      it { should_not be_able_to(:access, :admin) }
    end

    context "when is an admin user" do
      let(:user){ FactoryGirl.create(:admin) }

      it{ should be_able_to(:manage, :all) }
      it{ should be_able_to(:access, :rails_admin) }
      it{ should be_able_to(:access, :admin) }
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

      it{ should be_able_to(:access, :admin) }
      it{ should be_able_to(:manage, @org) }
      it{ should be_able_to(:manage, @child) }
      it{ should be_able_to(:manage, @org_content) }
      it{ should be_able_to(:manage, @child_content) }
    end

    context 'when is a regular user' do
      before do
        @user = FactoryGirl.create :user
        @content = FactoryGirl.create :content, created_by: @user
        @other_content = FactoryGirl.create :content, created_by: nil
      end

      let(:user){ @user }

      it { should be_able_to(:manage, @content) }
      it { should_not be_able_to(:manage, @other_content) }
    end
  end
end
