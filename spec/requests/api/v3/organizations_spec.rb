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
          profile_title: organization.profile_title || organization.name,
          can_publish_news: organization.can_publish_news,
          subscribe_url: organization.subscribe_url,
          logo_url: organization.logo_url,
          business_profile_id: a_kind_of(Fixnum).or(be_nil),
          description: organization.description,
          org_type: organization.org_type,
          can_edit: boolean,
          can_publish_events: organization.can_publish_events,
          can_publish_market: organization.can_publish_market,
          can_publish_talk: organization.can_publish_talk,
          can_publish_ads: organization.can_publish_ads,
          profile_ad_override: organization.profile_ad_override,
          profile_image_url: organization.profile_image.url,
          background_image_url: organization.background_image.url
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

    describe 'profile_title' do
      subject { response_json[:organization][:profile_title] }
      context 'when model.profile_title is empty' do
        before do
          organization.update(
            name: "test name",
            profile_title: nil
          )
        end

        it 'is equal to name' do
          get "/api/v3/organizations/#{organization.id}"
          expect(subject).to eql organization.name
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

    describe 'promotion ad override' do
      subject { response_json[:organization] }

      context 'when a profile_ad_override is empty' do
        it 'has promotion as nil' do
          get "/api/v3/organizations/#{organization.id}"
          expect(subject[:profile_ad_override]).to be_nil
        end
      end

      context 'when a profile_ad_override is present' do
        let!(:banner) { FactoryGirl.create :promotion_banner }
        let!(:promotion) { FactoryGirl.create :promotion, organization: organization, promotable: banner }

        before do
          organization.profile_ad_override = promotion.id
          organization.save!
        end

        it 'returns the id of the promotion' do
          get "/api/v3/organizations/#{organization.id}"
          expect(subject[:profile_ad_override]).to eql promotion.id
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

  describe 'PATCH /api/v3/organizations/:id' do
    let!(:organization) { FactoryGirl.create :organization }
    context 'when signed in and able to manage' do
      let(:user) { FactoryGirl.create :user }
      let(:auth_headers) { auth_headers_for(user) }
      let(:valid_params) {
        {
          name: 'Test name',
          profile_title: 'An interesting title',
          description: 'My biz description',
          subscribe_url: 'http://link.to/somewhere'
        }
      }

      before do
        user.roles << Role.create!(name: 'manager', resource: organization)
      end

      it 'updates' do
        expect{
          patch "/api/v3/organizations/#{organization.id}",
            {organization: valid_params},
            auth_headers
        }.to change{
            organization.reload.attributes.symbolize_keys.slice(
            :name, :profile_title, :subscribe_url,
            :description
          )
        }.to({
          name: valid_params[:name],
          profile_title: valid_params[:profile_title],
          subscribe_url: valid_params[:subscribe_url],
          description: valid_params[:description]
        })
      end
    end
  end
end
