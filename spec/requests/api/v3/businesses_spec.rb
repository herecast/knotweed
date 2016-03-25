require 'spec_helper'

describe 'Businesses Endpoints', type: :request do
  let(:user) { FactoryGirl.create :user }
  let(:auth_headers) { auth_headers_for(user) }

  describe 'GET /api/v3/businesses/:id' do
    context 'As an owner of the business' do
      let(:business) { FactoryGirl.create(:business_profile) }
      before do
        business.content.update_attribute(:created_by, user)
        get "/api/v3/businesses/#{business.id}", {}, auth_headers
      end

      it 'response includes can_edit=true' do
        expect(response_json['business']['can_edit']).to eql true
      end
    end

    context 'Not an owner of the business' do
      let(:business) { FactoryGirl.create(:business_profile) }
      before do
        business.content.update_attribute(:created_by, FactoryGirl.create(:user))
        get "/api/v3/businesses/#{business.id}", {}, auth_headers
      end

      it 'response includes can_edit=false' do
        expect(response_json['business']['can_edit']).to eql false
      end
    end

    context 'Not signed in' do
      let(:business) { FactoryGirl.create(:business_profile) }
      before do
        get "/api/v3/businesses/#{business.id}"
      end

      it 'response includes can_edit=false' do
        expect(response_json['business']['can_edit']).to eql false
      end
    end
  end

  describe 'GET /api/v3/businesses' do
    let(:url) { '/api/v3/businesses' }

    context 'a business existing that the current user owns' do
      let(:business) { FactoryGirl.create(:business_profile) }
      before do
        business.content.update_attribute(:created_by, user)
        business.business_location.update_attributes({
          latitude: Location::DEFAULT_LOCATION_COORDS[0],
          longitude: Location::DEFAULT_LOCATION_COORDS[1]
        })
        index
        get url, {}, auth_headers
      end

      it 'response includes business, and it has can_edit=true' do
        jbusiness = response_json['businesses'].find{|b| b['id'].eql? business.id}

        expect(jbusiness).to_not be nil
        expect(jbusiness['can_edit']).to be_true
      end
    end

    context 'Given several business profiles exist' do
      let!(:business_profiles) {
        FactoryGirl.create_list(:business_profile, 4)
      }

      describe 'meta.total' do
        before do
          index
        end

        it "is equal to the total items matching search" do
          get url, {
            per_page: 1,
            radius: 10_000 # we don't want distance to limit the query
          }
          meta_total = response_json['meta']['total']
          expect(meta_total).to eql business_profiles.size
        end
      end

      describe '?sort_by=score_desc' do
        before do
          tf = false
          business_profiles.each_with_index do |bp, i|
            # create some businesses with unique averages
            ((i+1) * 3).times do
              bf = FactoryGirl.build(:business_feedback, {
                business_profile: bp,
                recommend: tf
              })
              bf.save!
              bf.run_callbacks(:commit)
              tf = !tf
            end
          end

          index

          get url, {
            sort_by: 'score_desc',
            radius: 10_000 # we don't want distance to limit the query
          }
        end

        it 'returns business profiles sorted by feedback.recommend desc' do
          businesses = response_json['businesses']
          expect(businesses.count).to eql business_profiles.count

          sorted = businesses.sort_by{|b|  b['feedback']['recommend']}.reverse
          expect(businesses.first).to eql sorted.first
          expect(businesses.last).to eql sorted.last
        end
      end

      describe '?sort_by=distance_asc' do
        before do
          index
          get url, {
            sort_by: 'distance_desc',
            radius: 10_000 # we don't want distance to limit the query
          }
        end
        it 'returns business profiles sorted by geodist asc' do
          businesses = response_json['businesses']
          sorted = businesses.sort_by{|b| b['geodist']}

          expect(businesses.count).to eql business_profiles.count
          expect(businesses.first).to eql sorted.first
          expect(businesses.last).to eql sorted.last
        end
      end

      describe '?sort_by=rated_desc' do
        before do
          business_profiles.each_with_index do |bp, i|
            (i+1).times do
              bf = FactoryGirl.build :business_feedback, {
                business_profile: bp,
              }
              bf.save!
              bf.run_callbacks(:commit)
            end
          end

          index

          get url, {
            sort_by: 'rated_desc',
            radius: 10_000 # we don't want distance to limit the query
          }
        end
        it 'returns business profiles sorted by feedback_num desc' do
          businesses = response_json['businesses']
          sorted = businesses.sort_by{|b| b['feedback_num']}.reverse

          expect(businesses.count).to eql business_profiles.count
          expect(businesses.first).to eql sorted.first
          expect(businesses.last).to eql sorted.last
        end
      end

      describe '?sort_by=alpha_asc' do
        before do
          index
          get url, {
            sort_by: 'alpha_asc',
            radius: 10_000 # we don't want distance to limit the query
          }
        end
        it 'returns business profiles sorted alphabetically' do
          businesses = response_json['businesses']
          sorted = businesses.sort_by{|b| b['name']}

          expect(businesses.count).to eql business_profiles.count
          expect(businesses.first).to eql sorted.first
          expect(businesses.last).to eql sorted.last
        end
      end

      describe '?sort_by=alpha_desc' do
        before do
          index
          get url, {
            sort_by: 'alpha_desc',
            radius: 10_000 # we don't want distance to limit the query
          }
        end
        it 'returns business profiles sorted reverse alphabetically' do
          businesses = response_json['businesses']
          sorted = businesses.sort_by{|b| b['name']}.reverse

          expect(businesses.count).to eql business_profiles.count
          expect(businesses.first).to eql sorted.first
          expect(businesses.last).to eql sorted.last
        end
      end

      describe '?organization_id' do
        let(:organization) { FactoryGirl.create :organization }
        let(:owned_by_org) { FactoryGirl.create_list :business_profile, 3 }
        let(:not_owned_by_org) { FactoryGirl.create_list :business_profile, 3 }
        before do
          owned_by_org.each do |b|
            b.content.organization_id = organization.id
            b.save!
          end
          index
          get url, { organization_id: organization.id }
        end

        it 'only returns businesses owned by the organization' do
          returned_ids = response_json['businesses'].collect{|b| b['id']}

          expect(returned_ids).to include(*owned_by_org.collect(&:id))
          expect(returned_ids).to_not include(*not_owned_by_org.collect(&:id))
        end
      end
    end
  end
end
