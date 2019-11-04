# frozen_string_literal: true

require 'spec_helper'

describe 'CurrentUser endpoints', type: :request do
  describe 'GET /api/v3/current_user' do
    let(:headers) { {} }

    subject { get '/api/v3/current_user', headers: headers }

    context "when not signed in" do
      it "returns unauthorized status" do
        subject
        expect(response).to have_http_status :unauthorized
      end
    end

    context 'when signed in' do
      let(:user) { FactoryGirl.create :user }
      let(:headers) { auth_headers_for(user) }

      subject { get '/api/v3/current_user', headers: headers }

      it 'returns ok status' do
        subject
        expect(response).to have_http_status :ok
      end
    end
  end

  describe 'PUT /api/v3/current_user' do
    let(:headers) { {} }
    let(:params) { {} }

    subject { put '/api/v3/current_user', params: params, headers: headers }

    context "when not signed in" do
      it "returns unauthorized status" do
        subject
        expect(response).to have_http_status :unauthorized
      end
    end

    context "when signed in" do
      let(:user) { FactoryGirl.create :user }
      let(:headers) { auth_headers_for(user) }
      let(:params) do
        {
          current_user: {
            name: 'Skye Bill',
            location_id: FactoryGirl.create(:location).slug,
            location_confirmed: true,
            email: 'skye@bill.com',
            password: 'snever4aet3',
            password_confirmation: 'snever4aet3'
          }
        }
      end

      it "returns ok status" do
        subject
        expect(response).to have_http_status :ok
      end

      it "returns current_user in body" do
        subject
        expect(response_json.keys).to include(:current_user) 
      end

      context "when update fails" do
        before do
          allow_any_instance_of(User).to receive(
            :update_attributes
          ).and_return(false)
        end

        it "returns unprocessable_entity" do
          subject
          expect(response).to have_http_status :unprocessable_entity
        end
      end
    end
  end
end