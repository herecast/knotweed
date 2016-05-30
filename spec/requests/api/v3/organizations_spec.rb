require 'spec_helper'

RSpec.describe 'Organizations Endpoints' do
  describe 'GET /api/v3/organizations/:id' do
    let!(:organization) { FactoryGirl.create :organization }

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
