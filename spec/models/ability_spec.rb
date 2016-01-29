require 'spec_helper'
require "cancan/matchers"

describe Ability do
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

    context "when is an organization admin" do
      before do
        @user = FactoryGirl.create :user
        @org = FactoryGirl.create :organization
        @child = FactoryGirl.create :organization, parent: @org
        @user.add_role :manager, @org
      end

      let(:user){ @user }

      it{ should be_able_to(:access, :admin) }
      it{ should be_able_to(:manage, @org) }
      it{ should be_able_to(:manage, @child) }
    end

  end
end
