# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Organizations Endpoints', type: :request do
  describe 'GET /api/v3/organizations/:id' do
    let!(:organization) { FactoryGirl.create(:organization) }
    let!(:business_location) { FactoryGirl.create(:business_location) }

    it 'responds with organization json' do
      organization.business_locations << business_location
      get "/api/v3/organizations/#{organization.id}"
      expect(response_json).to match(
        organization: {
          id: organization.id,
          name: organization.name,
          can_publish_news: organization.can_publish_news,
          subscribe_url: organization.subscribe_url,
          business_profile_id: a_kind_of(Integer).or(be_nil),
          description: organization.description,
          org_type: organization.org_type,
          can_edit: boolean,
          profile_image_url: organization.profile_image.url,
          background_image_url: organization.background_image.url,
          twitter_handle: organization.twitter_handle,
          claimed: organization.business_locations.first.try(:business_profile).try(:claimed?) || false,
          custom_links: nil,
          biz_feed_active: organization.biz_feed_active,
          phone: organization.business_locations.first.phone,
          website: organization.business_locations.first.venue_url,
          hours: organization.business_locations.first.hours,
          email: organization.business_locations.first.email,
          address: organization.business_locations.first.address,
          city: organization.business_locations.first.city,
          state: organization.business_locations.first.state,
          zip: organization.business_locations.first.zip,
          certified_storyteller: organization.certified_storyteller,
          services: organization.services,
          contact_card_active: organization.contact_card_active,
          description_card_active: organization.description_card_active,
          hours_card_active: organization.hours_card_active,
          special_link_url: organization.special_link_url,
          special_link_text: organization.special_link_text,
          certified_social: organization.certified_social,
          desktop_image_url: organization.desktop_image_url,
          calendar_view_first: organization.calendar_view_first,
          calendar_card_active: organization.calendar_card_active,
          digest_id: organization.digest_id
        }
      )
    end

    context 'with claimed business_profile' do
      let!(:business_profile) { FactoryGirl.create :business_profile, :claimed, id: 100 }
      before do
        business_profile.content.organization = organization
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

    context 'when organization is archived' do
      before do
        @archived_org = FactoryGirl.create :organization,
                                           archived: true
      end

      subject { get "/api/v3/organizations/#{@archived_org.id}" }

      it 'returns not_found status' do
        subject
        expect(response).to have_http_status :not_found
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

    describe '?certified_[storyteller, social]', elasticsearch: :true do
      context 'when searching for certified_storyteller' do
        before do
          @non_storyteller = FactoryGirl.create :organization, certified_storyteller: false
          @storyteller = FactoryGirl.create :organization, certified_storyteller: true
        end

        subject { get '/api/v3/organizations?certified_storyteller=true' }

        it 'returns certified_storyteller Organizations' do
          subject
          expect(response_json[:organizations].length).to eq 1
          expect(response_json[:organizations][0][:id]).to eq @storyteller.id
        end
      end

      context 'when searching for certified_social' do
        before do
          @non_social = FactoryGirl.create :organization, certified_social: false
          @social = FactoryGirl.create :organization, certified_social: true
        end

        subject { get '/api/v3/organizations?certified_social=true' }

        it 'returns certified_social Organizations' do
          subject
          expect(response_json[:organizations].length).to eq 1
          expect(response_json[:organizations][0][:id]).to eq @social.id
        end
      end

      context 'when searching for certified_social and certified_storyteller' do
        before do
          @social = FactoryGirl.create :organization, certified_social: true
          @storyteller = FactoryGirl.create :organization, certified_storyteller: true
          @non_certified = FactoryGirl.create :organization,
                                              certified_social: false,
                                              certified_storyteller: false
        end

        subject { get '/api/v3/organizations?certified_social=true&certified_storyteller=true' }

        it 'returns certified_social and certified_storyteller Organizations' do
          subject
          expect(response_json[:organizations].length).to eq 2
          expect(response_json[:organizations].map { |o| o[:id] }).to match_array([@social.id, @storyteller.id])
        end
      end
    end
  end

  describe 'PATCH /api/v3/organizations/:id' do
    let!(:organization) { FactoryGirl.create :organization }
    context 'when signed in and able to manage' do
      let(:user) { FactoryGirl.create :user }
      let(:auth_headers) { auth_headers_for(user) }
      let(:valid_params) do
        {
          name: 'Test name',
          description: 'My biz description',
          subscribe_url: 'http://link.to/somewhere'
        }
      end

      before do
        user.roles << Role.create!(name: 'manager', resource: organization)
      end

      it 'updates' do
        expect do
          patch "/api/v3/organizations/#{organization.id}",
                params: { organization: valid_params },
                headers: auth_headers
        end.to change {
          organization.reload.attributes.symbolize_keys.slice(
            :name, :subscribe_url,
            :description
          )
        }.to(
          name: valid_params[:name],
          subscribe_url: valid_params[:subscribe_url],
          description: valid_params[:description]
        )
      end
    end
  end

  describe 'GET /api/v3/organizations/sitemap_ids' do
    let!(:org_biz) do
      FactoryGirl.create :organization,
                         org_type: 'Business',
                         biz_feed_active: true
    end
    let!(:org_publisher) do
      FactoryGirl.create :organization,
                         org_type: 'Publisher',
                         can_publish_news: true
    end
    let!(:org_blog) do
      FactoryGirl.create :organization,
                         org_type: 'Blog',
                         can_publish_news: true
    end
    let!(:org_publication) do
      FactoryGirl.create :organization,
                         org_type: 'Publication',
                         can_publish_news: true
    end
    let!(:org_listserv) do
      FactoryGirl.create :organization,
                         id: Organization::LISTSERV_ORG_ID,
                         org_type: 'Publisher',
                         biz_feed_active: true,
                         can_publish_news: true
    end

    subject do
      get '/api/v3/organizations/sitemap_ids'
      response_json
    end

    it 'does not return listserv' do
      expect(subject[:organization_ids]).to_not include org_listserv.id
    end

    it 'includes expected ids' do
      expect(subject[:organization_ids]).to include *[org_biz, org_publisher, org_blog, org_publication].map(&:id)
    end

    it 'does not include business with biz_feed_active=false' do
      org_biz.update biz_feed_active: false
      expect(subject[:organization_ids]).to_not include org_biz.id
    end

    it 'does not include publishing organizations with can_publish_news=false' do
      publisher_orgs = [org_publisher, org_blog, org_publication]
      publisher_orgs.each { |org| org.update can_publish_news: false }

      expect(subject[:organization_ids]).to_not include *publisher_orgs.map(&:id)
    end
  end
end
