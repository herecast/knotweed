# frozen_string_literal: true

require 'spec_helper'

describe 'Businesses Endpoints', type: :request do
  let!(:default_location) { FactoryGirl.create :location, :default }

  let(:user) { FactoryGirl.create :user }
  let(:auth_headers) { auth_headers_for(user) }

  describe 'GET /api/v3/businesses/:id' do
    context 'As an owner of the business' do
      # NOTE: if it has an owner, this is a claimed business,
      let(:business) { FactoryGirl.create(:business_profile, :claimed) }
      before do
        business.content.update_attribute(:created_by, user)
        get "/api/v3/businesses/#{business.id}", params: {}, headers: auth_headers
      end

      it 'response includes can_edit=true' do
        expect(response_json[:business][:can_edit]).to eql true
      end
    end

    context 'Not an owner of the business' do
      let(:business) { FactoryGirl.create(:business_profile, :claimed) }
      before do
        business.content.update_attribute(:created_by, FactoryGirl.create(:user))
        get "/api/v3/businesses/#{business.id}", params: {}, headers: auth_headers
      end

      it 'response includes can_edit=false' do
        expect(response_json[:business][:can_edit]).to eql false
      end
    end

    context 'Not signed in' do
      let(:business) { FactoryGirl.create(:business_profile) }
      before do
        get "/api/v3/businesses/#{business.id}"
      end

      it 'response includes can_edit=false' do
        expect(response_json[:business][:can_edit]).to eql false
      end
    end
  end

  describe 'GET /api/v3/businesses', elasticsearch: true do
    let(:url) { '/api/v3/businesses' }

    context 'a business existing that the current user owns' do
      let(:content) { FactoryGirl.create :content, created_by: user }
      let(:biz_location) { FactoryGirl.create :business_location,
                           latitude: default_location.latitude,
                           longitude: default_location.longitude,
                           address: nil
      }
      let!(:business) { FactoryGirl.create :business_profile, business_location: biz_location, content: content }

      subject { get url, params: {}, headers: auth_headers }

      it 'response includes business, and it has can_edit=true' do
        subject
        jbusiness = response_json[:businesses].find { |b| b[:id].eql? business.id }

        expect(jbusiness).to_not be nil
        expect(jbusiness[:can_edit]).to be_truthy
      end
    end

    context 'Given several business profiles exist' do
      let!(:business_profiles) do
        FactoryGirl.create_list(:business_profile, 4)
      end

      describe 'meta.total' do
        it 'is equal to the total items matching search' do
          get url, params: {
            per_page: 1,
            radius: 10_000 # we don't want distance to limit the query
          }
          meta_total = response_json[:meta][:total]
          expect(meta_total).to eql business_profiles.size
        end
      end

      describe '?sort_by=score_desc' do
        before do
          tf = false
          business_profiles.each_with_index do |bp, i|
            # create some businesses with unique averages
            ((i + 1) * 3).times do
              bf = FactoryGirl.build(:business_feedback,
                                     business_profile: bp,
                                     recommend: tf)
              bf.save!
              bf.run_callbacks(:commit)
              tf = !tf
            end
          end

          get url, params: {
            sort_by: 'score_desc',
            radius: 10_000 # we don't want distance to limit the query
          }
        end

        it 'returns business profiles sorted by feedback.recommend desc' do
          businesses = response_json[:businesses]
          expect(businesses.count).to eql business_profiles.count

          sorted = businesses.sort_by { |b| b[:feedback][:recommend] }.reverse
          expect(businesses.first).to eql sorted.first
          expect(businesses.last).to eql sorted.last
        end
      end

      describe '?sort_by=distance_asc' do
        before do
          get url, params: {
            sort_by: 'distance_desc',
            radius: 10_000 # we don't want distance to limit the query
          }
        end
        it 'returns business profiles sorted by geodist asc' do
          businesses = response_json[:businesses]
          sorted = businesses.sort_by { |b| b[:geodist] }

          expect(businesses.count).to eql business_profiles.count
          expect(businesses.first).to eql sorted.first
          expect(businesses.last).to eql sorted.last
        end
      end

      describe '?sort_by=rated_desc' do
        before do
          business_profiles.each_with_index do |bp, i|
            (i + 1).times do
              bf = FactoryGirl.build :business_feedback,
                                     business_profile: bp
              bf.save!
              bf.run_callbacks(:commit)
            end
          end

          get url, params: {
            sort_by: 'rated_desc',
            radius: 10_000 # we don't want distance to limit the query
          }
        end
        it 'returns business profiles sorted by feedback_num desc' do
          businesses = response_json[:businesses]
          sorted = businesses.sort_by { |b| b[:feedback_num] }.reverse

          expect(businesses.count).to eql business_profiles.count
          expect(businesses.first).to eql sorted.first
          expect(businesses.last).to eql sorted.last
        end
      end

      describe '?sort_by=alpha_asc' do
        before do
          get url, params: {
            sort_by: 'alpha_asc',
            radius: 10_000 # we don't want distance to limit the query
          }
        end
        it 'returns business profiles sorted alphabetically' do
          businesses = response_json[:businesses]
          sorted = businesses.sort_by { |b| b[:name] }
          expect(businesses.count).to eql business_profiles.count
          expect(businesses.first).to eql sorted.first
          expect(businesses.last).to eql sorted.last
        end
      end

      describe '?sort_by=alpha_desc' do
        before do
          get url, params: {
            sort_by: 'alpha_desc',
            radius: 10_000 # we don't want distance to limit the query
          }
        end
        it 'returns business profiles sorted reverse alphabetically' do
          businesses = response_json[:businesses]
          sorted = businesses.sort_by { |b| b[:name] }.reverse

          expect(businesses.count).to eql business_profiles.count
          expect(businesses.first).to eql sorted.first
          expect(businesses.last).to eql sorted.last
        end
      end

      describe '?organization_id' do
        let(:organization) { FactoryGirl.create :organization }
        let(:owned_by_org) { FactoryGirl.create_list :business_profile, 3, :claimed }
        let(:not_owned_by_org) { FactoryGirl.create_list :business_profile, 3 }
        before do
          owned_by_org.each do |b|
            b.content.organization_id = organization.id
            b.save!
          end
          get url, params: { organization_id: organization.id }
        end

        it 'only returns businesses owned by the organization' do
          returned_ids = response_json[:businesses].collect { |b| b[:id] }

          expect(returned_ids).to include(*owned_by_org.collect(&:id))
          expect(returned_ids).to_not include(*not_owned_by_org.collect(&:id))
        end
      end
    end
  end

  describe 'PUT /api/v3/businesses/:id' do
    let!(:business) { FactoryGirl.create(:business_profile, :claimed) }
    let!(:valid_params) do
      {
        name: 'Test new name',
        details: '<p>I am a robot</p>',
        email: 'my.new@email.com',
        has_retail_location: true,
        phone: '(555) 124-1234',
        hours: ['Mo-Th|8:00-17:00'],
        website: 'http://herecast.us',
        address: '123 foo st',
        city: 'Enfield',
        state: 'NH',
        zip: '03748',
        service_radius: 25
      }
    end
    context 'as owner of business' do
      before do
        business.content.update_attribute(:created_by, user)
      end

      subject { put "/api/v3/businesses/#{business.id}", params: { business: valid_params }, headers: auth_headers }

      it 'updates the business' do
        subject
        business_json = response_json[:business]

        expect(business_json).to match(
          id: business.id,
          organization_id: business.content.organization_id,
          name: valid_params[:name],
          phone: valid_params[:phone],
          email: valid_params[:email],
          website: valid_params[:website],
          address: valid_params[:address],
          city: valid_params[:city],
          state: valid_params[:state],
          zip: valid_params[:zip],
          has_retail_location: valid_params[:has_retail_location],
          service_radius: a_kind_of(Integer),
          hours: valid_params[:hours],
          feedback_num: a_kind_of(Integer),
          can_edit: true,
          # @TODO:  details: valid_params[:details],
          # Details gets another <p></p> wrapped around it.
          # Needs to be looked at.
          details: an_instance_of(String),
          logo: an_instance_of(String).or(be_nil),
          images: an_instance_of(Array),
          category_ids: an_instance_of(Array),
          feedback: {
            satisfaction: an_instance_of(Float),
            cleanliness: an_instance_of(Float),
            price: an_instance_of(Float),
            recommend: an_instance_of(Float)
          },
          coords: {
            lat: an_instance_of(Float),
            lng: an_instance_of(Float)
          },
          has_address: be_in([true, false]),
          has_rated: be_in([true, false]),
          claimed: be_in([true, false]),
          biz_feed_active: be_in([true, false])
        )
      end
    end
  end
end
