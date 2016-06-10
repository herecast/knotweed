require 'spec_helper'

RSpec.describe 'Organizations Endpoints', type: :request do
  describe 'GET /api/v3/organizations/:id' do
    let!(:organization) { FactoryGirl.create :organization }

    it 'responds with organization json' do
      get "/api/v3/organizations/#{organization.id}"
      expect(response_json).to match(
        organization: {
          id: organization.id,
          name: organization.name,
          can_publish_news: organization.can_publish_news,
          subscribe_url: organization.subscribe_url,
          logo_url: an_instance_of(String).or(be_nil),
          business_profile_id: a_kind_of(Fixnum).or(be_nil),
          description: organization.description,
          org_type: organization.org_type,
          can_edit: boolean
        }
      )
    end

    context 'with claimed business_profile' do
      let!(:business_profile) { FactoryGirl.create :business_profile, :claimed, id: 100 }
      before do
        business_profile.content.organization= organization
        business_profile.content.save!
      end

      describe 'business_profile_id' do
        subject { response_json[:organization][:business_profile_id] }

        it 'is business_profile.id' do
          get "/api/v3/organizations/#{organization.id}"
          expect(subject).to eql business_profile.id
        end
      end
    end

    describe 'can_edit' do
      subject { response_json[:organization][:can_edit] }

      context 'When ability allows for edit' do
        before do
          allow_any_instance_of(Ability).to receive(:can?).with(:edit, organization).and_return(true)
          get "/api/v3/organizations/#{organization.id}"
        end

        it 'is true' do
          expect(subject).to eql true
        end
      end

      context 'When ability does not allow edit' do
        before do
          allow_any_instance_of(Ability).to receive(:can?).with(:edit, organization).and_return(false)
          get "/api/v3/organizations/#{organization.id}"
        end

        it 'is false' do
          expect(subject).to eql false
        end
      end
    end
  end

  describe 'GET /api/v3/organizations' do

    describe 'can_edit' do
      let!(:organization1) { FactoryGirl.create :organization }
      subject { response_json[:organizations][0][:can_edit] }

      context 'When ability allows for edit' do
        before do
          allow_any_instance_of(Ability).to receive(:can?).with(:edit, organization1).and_return(true)
          get "/api/v3/organizations?ids[]=#{organization1.id}"
        end

        it 'is true' do
          expect(subject).to eql true
        end
      end

      context 'When ability does not allow edit' do
        before do
          allow_any_instance_of(Ability).to receive(:can?).with(:edit, organization1).and_return(false)
          get "/api/v3/organizations?ids[]=#{organization1.id}"
        end

        it 'is false' do
          expect(subject).to eql false
        end
      end
    end
  end
end
