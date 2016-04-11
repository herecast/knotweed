require 'spec_helper'

describe ContentSetsController, type: :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  describe 'GET #index'do
    let(:records) { FactoryGirl.create_list :content_set, 3 }
    let(:mock_result) {
      double(result: records)
    }

    it 'sets up @search' do
      get :index
      expect(assigns(:search)).to be_an_instance_of Ransack::Search
    end

    context 'Given parameter ?q' do
      let(:query) { {"fake" => "Search"} }

      it 'returns searched records' do
        expect(ContentSet).to receive(:ransack).with(query).and_return(mock_result)
        get :index, q: query
        expect(assigns(:content_sets)).to eql records
      end

      it 'stores query in session' do
        session[:content_sets_search] = nil
        get :index, q: query
        expect( session[:content_sets_search] ).to eql query
      end
    end

    context 'When session remembers query; no ?q param given' do
      let(:query) { {"fake" => "Search"} }
      before do
        session[:content_sets_search] = query
      end

      it 'uses remembered query' do
        expect(ContentSet).to receive(:ransack).with(query).and_return(mock_result)
        get :index
      end
    end

    context 'Given ?reset parameter' do
      before do
        session[:content_sets_search] = {"fake" => "Search"}
      end

      it 'clears the saved search' do
        get :index, reset: true
        expect( session[:content_sets_search] ).to eql nil
      end
    end

    context 'Given no parameters' do
      it 'returns ContentSet.all' do
        expect(ContentSet).to receive(:where).and_return(records)
        get :index
        expect(assigns(:content_sets)).to eq records
      end
    end
  end

  describe 'PUT #update' do
    let(:record) { FactoryGirl.create :content_set }
    let(:attrs) { {"name" => "Da NAME"} }
    subject{ put :update, id: record.id, content_set: attrs }

    before do
      allow(ContentSet).to receive(:find).and_return(record)
    end

    context 'when invalid' do
      before do
        allow(record).to receive(:update_attributes).and_return(false)
      end

      it 're-renders "edit" template' do
        expect( subject ).to render_template('content_sets/edit')
      end
    end

    context 'when valid' do
      it 'updates attributes' do
        expect{ subject }.to change{ record.name }
      end

      it 'redirects to content_sets_path' do
        subject
        expect(response).to redirect_to(content_sets_path)
      end

      context 'given parameter ?add_import_job' do
        it 'redirects to new_import_job_path' do
          put :update, id: record.id, content_set: attrs, add_import_job: true
          expect(response).to redirect_to( new_import_job_path(import_job: {content_set_id: record.id, organization_id: record.organization_id})  )
        end
      end
    end
  end

  describe 'POST #create' do
    let(:attrs) { FactoryGirl.attributes_for(:content_set).merge(organization_id: FactoryGirl.create(:organization).id)}
    subject {
      post :create, content_set: attrs
    }

    context 'When invalid' do
      before do
        allow_any_instance_of(ContentSet).to receive(:save).and_return(false)
      end

      it 're renders "new" template' do
        subject
        expect(response).to render_template('content_sets/new')
      end
    end

    context 'When valid' do
      it 'creates a record' do
        expect{ subject }.to change{ ContentSet.count }.by(1)
      end

      it 'redirects to content_sets_path' do
        subject
        expect(response).to redirect_to(content_sets_path)
      end

      context 'given parameter ?add_import_job' do
        it 'redirects to new_import_job_path' do
          post :create, content_set: attrs, add_import_job: true
          record = ContentSet.last
          expect(response).to redirect_to( new_import_job_path(import_job: {content_set_id: record.id, organization_id: record.organization_id})  )
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:record) { FactoryGirl.create :content_set }
    before do
      allow(ContentSet).to receive(:find).and_return(record)
    end

    it 'destroys record' do
      expect(record).to receive(:destroy)
      delete :destroy, id: record.id
    end
  end
end
