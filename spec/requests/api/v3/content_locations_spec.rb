require 'rails_helper'

RSpec.describe 'Content Locations API Endpoints', type: :request do

  describe 'DELETE /api/v3/content_locations/:id' do
    let!(:content) {
      FactoryGirl.create :content,
      content_locations: [ContentLocation.create!(location: FactoryGirl.create(:location))]
    }

    context 'user signed in' do
      let(:user) { FactoryGirl.create :user }
      let(:auth_headers) { auth_headers_for(user) }

      subject do
        delete "/api/v3/content_locations/#{content.content_locations.first.id}", {}, auth_headers
      end

      context 'User can edit content' do
        before do
          content.update! created_by: user
        end

        it 'deletes the content location record' do
          expect{
            subject
          }.to change{
            content.reload.content_locations.count
          }.by(-1)
        end

        it 'returns 204 status' do
          subject
          expect(response.status).to eql 204
        end
      end

      context 'User not allowed to edit' do
        before do
          content.update! created_by: FactoryGirl.create(:user)
        end

        it 'returns a 403' do
          subject
          expect(response.status).to eql 403
        end

        it 'does not delete the content location record' do
          expect{
            subject
          }.to_not change{
            content.reload.content_locations.count
          }
        end
      end
    end

    context 'not signed in' do
      subject do
        delete "/api/v3/content_locations/#{content.content_locations.first.id}"
      end

      it 'returns 401' do
        subject
        expect(response.status).to eql 401
      end

      it 'does not delete the content location record' do
        expect{
          subject
        }.to_not change{
          content.reload.content_locations.count
        }
      end
    end
  end
end
