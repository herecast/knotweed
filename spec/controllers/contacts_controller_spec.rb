require 'spec_helper'

describe ContactsController, type: :controller do
  before do
    sign_in FactoryGirl.create(:admin)
  end

  describe '#new' do
    it 'renders form partial' do
      get :new
      expect(response).to render_template('contacts/_form')
    end

    context 'given a model, and id parameter' do
      let!(:organization) { FactoryGirl.create :organization }

      it 'sets the appropriate instance var' do
        get :new, model: Organization, id: organization.id
        expect(assigns(:organization)).to eql organization
      end
    end
  end

  describe '#create' do
    let(:attrs) { FactoryGirl.attributes_for :contact }
    it 'creates a record' do
      expect{ post :create, contact: attrs }.to change{
        Contact.count
      }.by(1)
    end
  end

  context 'Given a contact record' do
    let(:record) { FactoryGirl.create :contact }
    before do
      allow(Contact).to receive(:find).and_return(record)
    end

    describe '#edit' do
      before do
        get :edit, id: record.id, format: :js
      end

      it 'renders form partial' do
        expect(response).to render_template('contacts/_form')
      end

      it 'sets instance var needed by form' do
        expect(assigns(:contact)).to eql record
      end
    end

    describe '#update' do
      it 'updates record' do
        put :update, id: record.id, format: :js, contact: { name: 'Yolanda' }
        expect(record.reload.name).to eql 'Yolanda'
      end
    end

    describe '#destroy' do
      it 'destroys the record' do
        expect(record).to receive(:destroy)
        delete :destroy, id: record.id
      end
    end
  end
end
