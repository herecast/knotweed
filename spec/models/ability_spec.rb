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
      let(:user){ FactoryGirl.create(:organization_admin) }

      it{ should be_able_to(:access, :admin) }
      it{ should be_able_to(:update, user.organization) }
    end

  end

end
