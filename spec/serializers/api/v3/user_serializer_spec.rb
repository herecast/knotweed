require 'spec_helper'

describe Api::V3::UserSerializer do
  before do
    @user = FactoryGirl.create :user
  end

  let (:serialized_object) { JSON.parse(Api::V3::UserSerializer.new(@user, 
        root: false, context: { current_ability: @user.ability } ).to_json) }

  describe 'managed_organization_ids' do
    before do
      @org = FactoryGirl.create :organization
      @child_org = FactoryGirl.create :organization, parent: @org
      @user.add_role :manager, @org
    end

    it 'should list all managed organizations and their children' do
      serialized_object['managed_organization_ids'].should match_array([@org.id, @child_org.id])
    end
  end
end
