require 'spec_helper'

describe 'Businesses Endpoints' do
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
    context 'a business existing that the current user owns' do
      let(:business) { FactoryGirl.create(:business_profile) }
      before do
        business.content.update_attribute(:created_by, user)
        business.business_location.update_attributes({
          latitude: Location::DEFAULT_LOCATION_COORDS[0],
          longitude: Location::DEFAULT_LOCATION_COORDS[1]
        })
        index
        get "/api/v3/businesses", {}, auth_headers
      end

      it 'response includes business, and it has can_edit=true' do
        jbusiness = response_json['businesses'].find{|b| b['id'].eql? business.id}

        expect(jbusiness).to_not be nil
        expect(jbusiness['can_edit']).to be_true
      end
    end
  end
end
