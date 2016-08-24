require 'spec_helper'

describe 'Events Endpoints', type: :request do
  let(:user) { FactoryGirl.create :user }
  let(:auth_headers) { auth_headers_for(user) }

  describe 'can_edit' do
    let(:event) { FactoryGirl.create :event }

    context 'when ability allows for edit' do
      before do
        allow_any_instance_of(Ability).to receive(:can?).with(:manage, event.content).and_return(true)
      end

      it "returns true" do
        get "/api/v3/events/#{event.id}"
        expect(response_json[:event][:can_edit]).to eql true
      end
    end

    context 'when ability does not allow to edit' do
      let(:put_params) do
        {
          title: 'blerb',
          content: Faker::Lorem.paragraph,
        }
      end

      it "returns false" do
        allow_any_instance_of(Ability).to receive(:can?).with(:manage, event.content).and_return(false)
        get "/api/v3/events/#{event.id}"
        expect(response_json[:event][:can_edit]).to eql false
      end

      it 'does not allow a user to send an update' do
        put "/api/v3/events/#{event.id}", { event: put_params }, auth_headers
        expect(response.status).to eql 403
      end
      
    end
  end
end
